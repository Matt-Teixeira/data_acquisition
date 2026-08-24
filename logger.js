const { createLogger, format, transports } = require('winston');
const { combine, timestamp, printf } = format;

const customFormat = printf(({ level, timestamp, message }) => {
   const { text, jobId } = message;
   let msg = `[${level.toUpperCase()} - ${jobId}]\n[${timestamp}]\n${text}\n[/${level.toUpperCase()} - ${jobId}]\n`;
   return msg;
});

let now = new Date();
now = now.toISOString();

const logger = createLogger({
  level: "info",
  format: combine(timestamp(), customFormat),
  transports: [
    new transports.File({
      filename: `./logs/adp.${process.env.USER_ID}_${now}.log`,
    }),
  ],
});

if (process.env.LOGGER_MODE === 'log_and_console') {
   logger.add(
      new transports.Console({
         format: combine(timestamp(), customFormat),
      })
   );
}

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
         // TODO: MABYE CONVERT IF/ELSE TO IF->BREAK LOOP, THIS BECASUE
         // args DOESN'T NEED LOOPING IF Error IS DETECTED, I THINK???
         if (argType === 'error') {
            // IF ERROR HAS STACKTRACE PRINT THAT, OTHERWISE STANDARD PRINT
            // IF FN THROWS args WILL ONLY CONTAIN 1 ITEM, AN error OBJECT
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

   // THE LOGGER API IS PARTICULAR ABOUT VALUES PASSED, IT ONLY ACCEPTS ARG NAMED message
   // BUT WE WANT CUSTOM FORMATTING IN customFormat, SO MESSAGE IS OVERWRITTEN WITH THE MESSAGE OBJ
   message = { text: message, jobId: jobId };

   switch (level) {
      case 'error':
         logger.error(message);
         break;
      case 'warn':
         logger.warn(message);
         break;
      default:
         logger.info(message);
         break;
   }
};

const loudPrint = (text) => {
   console.log('###################################################');
   console.log(text);
   console.log('###################################################');
};

module.exports = { log, loudPrint };

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
