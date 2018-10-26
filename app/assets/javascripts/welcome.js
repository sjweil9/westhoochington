var ready = function() {
  $('a.flip').click(function(e){
      e.preventDefault();
      $('form').animate({height: "toggle", opacity: "toggle"}, "slow");
  });
};

$(document).ready(ready);
$(document).on('page:change', ready);