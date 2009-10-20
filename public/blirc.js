window.addEvent('domready', function(){
    var lock = false
    timer = function(){
    if(lock) return;
    lock = true;
    new Request.HTML({ 
      url: '/refresh', 
      method: 'get',
      evalScripts: false,
      onComplete: function(response)
      {
        $('console').adopt(response);
        $('console').scrollTop = $('console').scrollHeight;
        lock = false;
      }
    }).send()
  }.periodical(5000);
});


