// logger.js — free-text breadcrumb logger (console-only).
//
// History: this was a winston side-logger writing per-run files to ./logs/
// (adp.<USER_ID>_<ISO>.log). Retired 2026-08-27 (FLEET-TODO 2b decision 7):
// ~70% of the files it created were empty, none were operationally read, and
// the structured logger (utils/logger/log.js -> util.app_run_logs + per-run
// JSON) is the run record. The ~43 call sites across jobs/read/redis/sql
// keep their signature; only the sink changed:
//   error/warn -> console.error ALWAYS (lands in the bounded cron .out)
//   info/debug -> console.log only when LOGGER_MODE=log_and_console (dev)
// No file writes, no ./logs directory, no winston dependency.

const getConstructorType = async (value) => {
   switch (value.constructor) {
      case Number:
         return 'number';
      case Boolean:
         return 'boolean';
      case String:
         return 'string';
      case Array:
         return 'array';
      case Object:
         return 'object';
      // NEVER SEEN THESE FIRE YET
      case Function:
         return 'function';
      case Error:
         return 'error';
      default:
         return 'Undetermined Type: Manual Check For Future Reference';
   }
};

const log = async (level, jobId, sme, fn, note, args) => {
   let message = `[${fn} - ${note}]`;

   // args -> [{},{}...]
   // LOOP THROUGH ARGS SO WE CAN LOG THE ARG NAME, TYPE AND VALUE
   if (args) {
      let argInfo = '';
      for (const [key, value] of Object.entries(args)) {
         let argType;
         switch (value) {
            case undefined:
               argType = 'undefined';
               break;
            case null:
               argType = 'null';
               break;
            default:
               argType = await getConstructorType(value);
         }

         // CHECK FOR error.stack FOR MORE INFORMATIVE LOGGING
         if (argType === 'error') {
            // IF ERROR HAS STACKTRACE PRINT THAT, OTHERWISE STANDARD PRINT
            argInfo = `\n[${key}] - [${argType}] - [${
               value.stack ? value.stack : value
            }]`;
         } else {
            // STRINGFY object OR array FOR MORE INFORMATIVE LOGGING
            argInfo =
               argInfo +
               `\n[${key}] - [${argType}] - [${
                  argType === 'object'
                     ? JSON.stringify(value)
                     : argType === 'array'
                     ? JSON.stringify(value)
                     : value
               }]`;
         }
      }

      message = message + argInfo;
   }

   const lvl = level === 'error' || level === 'warn' ? level : 'info';
   const stamp = new Date().toISOString();
   const text = `[${lvl.toUpperCase()} - ${jobId}]\n[${stamp}]\n${message}\n[/${lvl.toUpperCase()} - ${jobId}]\n`;

   if (lvl === 'error' || lvl === 'warn') {
      console.error(text);
   } else if (process.env.LOGGER_MODE === 'log_and_console') {
      console.log(text);
   }
};

module.exports = { log };

// EXAMPLE
// let someUndefVar;
//    await log('info', jobId, 'NA', 'runJob', `FN CALL`, {
//       undefinedTest: someUndefVar,
//       nullTest: null,
//       numTest: 9,
//       boolTest: true,
//       stringTest: 'a string',
//       arrayTest: ['an', 'array'],
//       objTest: { aKey: 'a value' },
//    });
