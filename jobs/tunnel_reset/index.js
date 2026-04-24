const getTunnelsByIP = require("../../utils/vpn/get-tunnels-by-ip");
const resetTunnels = require("../../utils/vpn/reset-tunnels");
const { get_redis_ip_queue, clear_redis_ip_queue } = require("../../redis");
const { extract_ip, captureDatetime } = require("../../util");
const { retryHhmSystem } = require("../hhm/_shared");
const { getConfig } = require("../hhm/_configs");
const get_philips_cv_data_retry = require("./philips/philips_cv");
const execRsync = require("../mmb/read/exec-rsync");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat },
} = require("../../utils/logger/enums");
const { setTimeout } = require("timers/promises");
const { v4: uuidv4 } = require("uuid");

async function reset_tunnel(run_log) {
  const capture_datetime = captureDatetime();
  try {
    const ip_queue = await get_redis_ip_queue();

    if (!ip_queue.length) {
      await addLogEvent(
        I,
        run_log,
        "reset_tunnel",
        det,
        { message: "No IP addresses in queue" },
        null
      );
      return;
    }

    await addLogEvent(I, run_log, "reset_tunnel", cal, { ip_queue }, null);

    const parsed_data = extract_ip(ip_queue);
    const tunnels_by_ip = await getTunnelsByIP(
      run_log,
      parsed_data.ip_addresses
    );
    await addLogEvent(
      I,
      run_log,
      "reset_tunnel",
      det,
      { tunnels: tunnels_by_ip },
      null
    );

    if (!tunnels_by_ip) {
      await addLogEvent(
        W,
        run_log,
        "reset_tunnel",
        det,
        {
          message: "No tunnels assocciated with systems",
          systems: parsed_data.id,
        },
        null
      );
      return;
    }

    /*
    const [ip_tunnels_1, ip_tunnels_2] = split_array(tunnels_by_ip);
    await setTimeout(4_000);
    await resetTunnels(run_log, ip_tunnels_1);
    await setTimeout(5_000);
    await resetTunnels(run_log, ip_tunnels_2);
    */
    // await resetTunnels(run_log, tunnels_by_ip);

    await clear_redis_ip_queue();

    console.log("Start of 5 second timer");
    await setTimeout(5_000);
    console.log("End of timer");

    // Pre-fetch credentials once per unique (manufacturer, modality) so
    // multiple queued systems of the same type don't re-run the cred query.
    const credsCache = new Map();
    for (const system of ip_queue) {
      if (system.data_source === "mmb") continue;
      if (system.manufacturer === "Philips" && system.modality === "CV/IR") continue;
      const config = getConfig(system.manufacturer, system.modality);
      if (!config || !config.fetchCredentials) continue;
      const key = `${config.manufacturer}:${config.modality}`;
      if (!credsCache.has(key)) {
        credsCache.set(
          key,
          await config.fetchCredentials([config.manufacturer, config.modality])
        );
      }
    }

    const jobs = [];
    for (const system of ip_queue) {
      const job_id = uuidv4();

      if (system.data_source === "mmb") {
        jobs.push(
          async () =>
            await execRsync(
              run_log,
              job_id,
              system.id,
              `./jobs/mmb/read/sh/rsync_mmb.sh`,
              system.rsyncShArgs,
              capture_datetime,
              true,
              true
            )
        );
        continue;
      }

      // philips_cv is a multi-stage outlier — different exec path
      // (exec_phil_cv_data_grab) — keep its dedicated retry bridge.
      if (system.manufacturer === "Philips" && system.modality === "CV/IR") {
        jobs.push(
          async () =>
            await get_philips_cv_data_retry(
              job_id,
              run_log,
              system,
              capture_datetime,
              true
            )
        );
        continue;
      }

      const config = getConfig(system.manufacturer, system.modality);
      if (!config) {
        await addLogEvent(
          W,
          run_log,
          "reset_tunnel",
          det,
          {
            message: "No HHM config registered for (manufacturer, modality)",
            system_id: system.id,
            manufacturer: system.manufacturer,
            modality: system.modality,
          },
          null
        );
        continue;
      }

      const credKey = `${config.manufacturer}:${config.modality}`;
      const creds = credsCache.get(credKey) || null;

      jobs.push(
        async () =>
          await retryHhmSystem(
            run_log,
            system,
            job_id,
            capture_datetime,
            config,
            creds
          )
      );
    }

    try {
      const promises = jobs.map((job) => job());
      await Promise.all(promises);

      const ip_queue_post_reset = await get_redis_ip_queue();
      await clear_redis_ip_queue();

      if (!ip_queue_post_reset.length) return;

      await addLogEvent(
        I,
        run_log,
        "reset_tunnel",
        det,
        {
          message: "Data not acquired post tunnel reset",
          ip_queue_post_reset,
        },
        null
      );
    } catch (error) {
      await addLogEvent(E, run_log, "reset_tunnel", cat, null, error);
    }
  } catch (error) {
    console.log(error);
    await addLogEvent(E, run_log, "reset_tunnel", cat, null, error);
  }
}

module.exports = reset_tunnel;
