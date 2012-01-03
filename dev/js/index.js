(function(){
    var template1 = _.template($('#home-template').html());
    var template2 = _.template($('#home-template2').html());
    var $container = $('#container')
    // Just a random int array.
    var numbers = _.range(10);

    $container.html(template1({
        message: 'Hi there!'
    }));

    $container.append(template2({
        numbers: numbers
    }));

    // If this is IE, include respond.js for IE6-8 media query support.
    if ($.browser.msie){
        (function(d){
            var s= d.createElement('script');
            s.src = 'js/respond.min.js';
            document.body.appendChild(s);
        })(document);
    }
})();