### Install:
    npm install simple-logger

### Usage:
    var log = require('simple-logger')

    // Warn
    log.warn('hello!');

    // Change log level (info, warn, error) (default is warn)
    log.log_level = 'warn';

### Fun Facts:
Log multiple objects in one call!

    log.warn('hello', [1,2,3]);
    May 15:22:33 - WARN: hello 1,2,3

Objects are auto-inspected

    log.warn({foo: 'bar', duck: 'pie'});
    27 May 15:22:53 - WARN: { foo: 'bar', duck: 'pie' }
 
### Neato: 
![Screenshot of colorful logger output](http://andrewray.me/stuff/log-colors.png)
