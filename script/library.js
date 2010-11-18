/* part.js */

function refresh(event) {
    $("#subset").submit();
}

$(document).ready(function(){
    $("#display").change(refresh);
    $("#publisher").change(refresh);
    $("#author").change(refresh);
    $("#tag").change(refresh);
    $("#rating").change(refresh);
    $("#orderby").change(refresh);
});
