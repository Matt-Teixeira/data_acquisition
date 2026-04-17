const getTunnelsByIP = require("../../utils/vpn/get-tunnels-by-ip");
const resetTunnels = require("../../utils/vpn/reset-tunnels");
const { get_redis_ip_queue, clear_redis_ip_queue } = require("../../redis");
const { extract_ip, captureDatetime } = require("../../util");
const get_philips_data = require("./philips");
const get_ge_data = require("./ge");
const get_siemens_data = require("./siemens");
const execRsync = require("../mmb/read/exec-rsync");
const [addLogEvent] = require("../../utils/logger/log");
const {
  type: { I, W, E },
  tag: { cal, det, cat, seq, qaf }
} = require("../../utils/logger/enums");
const { setTimeout } = require("timers/promises");
const { v4: uuidv4 } = require("uuid");

async function reset_tunnel(run_log) {
  const capture_datetime = captureDatetime();
  try {
    // Get Redis systems that need tunnel resets
    const ip_queue = await get_redis_ip_queue();

    // End if no systems in redis queue

    if (!ip_queue.length) {
      let note = { message: "No IP addresses in queue" };
      await addLogEvent(I, run_log, "reset_tunnel", det, note, null);
      return;
    }

    await addLogEvent(I, run_log, "reset_tunnel", cal, { ip_queue }, null);

    // Parse system data to get array of ip addresses and ids
    const parsed_data = extract_ip(ip_queue);

    // Group IP by tunnel id
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
      let note = {
        message: "No tunnels assocciated with systems",
        systems: parsed_data.id
      };
      await addLogEvent(W, run_log, "reset_tunnel", det, note, null);
      return;
    }
    // Reset tunnels

    /* 
    const [ip_tunnels_1, ip_tunnels_2] = split_array(tunnels_by_ip);
    await setTimeout(4_000);
    await resetTunnels(run_log, ip_tunnels_1);
    await setTimeout(5_000);
    await resetTunnels(run_log, ip_tunnels_2);  
    */

    // await resetTunnels(run_log, tunnels_by_ip);

    // Clear Redis queue
    await clear_redis_ip_queue();

    // Timer set to allow tunnel resets to complete
    console.log("Start of 5 second timer");
    await setTimeout(5_000);
    console.log("End of timer");

    /* Re-run Data Acquisition */
    const jobs = [];

    for (const system of ip_queue) {
      const job_id = uuidv4();
      // Check for possible duplicates in queue and prevent double runs
      // let is_duplicate = ran_systems.indexOf(system.id);
      // if (is_duplicate !== -1) continue;

      // Check for and run mmb systems
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

      // Check for and run hhm systems
      switch (system.manufacturer) {
        case "GE":
          jobs.push(
            async () =>
              await get_ge_data(job_id, run_log, system, capture_datetime, true)
          );
          break;
        case "Philips":
          jobs.push(
            async () =>
              await get_philips_data(
                job_id,
                run_log,
                system,
                capture_datetime,
                true
              )
          );
          break;
        case "Siemens":
          jobs.push(
            async () =>
              await get_siemens_data(
                job_id,
                run_log,
                system,
                capture_datetime,
                true
              )
          );
          break;
        default:
          break;
      }
      // ran_systems.push(system.id);
    }

    try {
      // CREATE AN ARRAY OF PROMISES BY CALLING EACH child_process FUNCTION
      const promises = jobs.map((job) => job());

      // AWAIT PROMISIS
      await Promise.all(promises);

      // Check queue for systems in which tunnel resets did not resolve connection issue
      const ip_queue_post_reset = await get_redis_ip_queue();

      // Clear Redis queue
      await clear_redis_ip_queue();

      // No systems in queue. All resets effective
      if (!ip_queue_post_reset.length) return;

      // Else: log and insert into db, systems that timeout after tunnel reset
      let note = {
        message: "Data not acquired post tunnel reset",
        ip_queue_post_reset
      };
      addLogEvent(I, run_log, "reset_tunnel", det, note, null);
    } catch (error) {
      addLogEvent(E, run_log, "reset_tunnel", cat, null, error);
    }
  } catch (error) {
    console.log(error);
    addLogEvent(E, run_log, "reset_tunnel", cat, null, error);
  }
}

module.exports = reset_tunnel;

async function insertOfflineAlerts(ip_queue, capture_datetime) {
  try {
    //await insertAlertTable(ip_queue, capture_datetime);
  } catch (error) {
    let note = {
      ip_queue,
      capture_datetime
    };
    console.log(error);
    addLogEvent(E, run_log, "insertOfflineAlerts", cat, note, error);
  }
}

function split_array(arr) {
  let mid_index = Math.ceil(arr.lengh / 2);
  const first_half = arr.slice(0, mid_index);
  const second_half = arr.slice(mid_index);
  return [first_half, second_half];
}
