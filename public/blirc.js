window.addEvent('domready', function(){
  var lock = false;
  var request;
  var timer = function(){
    if(lock) return;
    lock = true;
    request = new Request.HTML({ 
      url: '/refresh', 
      method: 'get',
      evalScripts: false,
      onComplete: function(response){
        $('console').adopt(response);
        $('console').scrollTop = $('console').scrollHeight;
        lock = false;
      }
    }).send()
  }.periodical(5000);

  $('input').addEvent('keyup', function(event){
    if(event.key=='enter' && $('input').value != '' && !lock){
      lock = true;  
      new Request.HTML({ 
        url: '/update', 
        method: 'post',
        data: {'text': $('input').value},
        evalScripts: false,
        onComplete: function(response){
          $('input').value = '';
          //$('console').adopt(response);
          $('console').scrollTop = $('console').scrollHeight;
          request.send();
        }
      }).send()
    }
  });
});



