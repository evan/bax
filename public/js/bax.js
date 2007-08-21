
function Submit(e) {
  
  var params = {}; 
  $('form').find("input, textarea").each(
    function() {params[this.name] = this.value; }
  );  

  if (e.name == "submit") params['article'] = document.location.href;
  
  $.post("/script/bax.rb", /* send request */
    params, 
    function(d) { /* preview callback */
      $('#preview').html(d);
      $('#preview').fadeIn();      
      if (params['article']) { 
        if ($('#preview[p.error]').size() == 0) {
          /* disable form */
          $('#comment-message').html("Thanks for your comment!");
          $('form').fadeOut();
        }
      }
    }
  )  
}
