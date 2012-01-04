// Silence logging for those that don't support it.
if (!window.console || window.console && (!window.console.log || !window.console.error)){
    window.console = {};
    console.log = console.warn = console.error = function(){};
}