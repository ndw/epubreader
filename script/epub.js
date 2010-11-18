/* epub */

function change_stars(event) {
    var stars = this.id.substring(4)
    var uri = document.location + "";

    $.get("/ajax.xqy", {
        "action" : "rating",
        "rating" : stars,
        "book"   : uri
    }, confirmStars);
}

function confirmStars(data) {
    var rating = data.getElementsByTagName("rating");

    if (rating.length > 0) {
        rating = $(rating[0]).text();

        for (var star = 1; star <= 5; star++) {
            var id = "star"+star
            var elem = $("#"+id);
            if (rating >= star) {
                elem.attr("class", "star on")
            } else {
                elem.attr("class", "star off")
            }
        }

        if (rating == 0) {
            $("#star0").attr("class", "star on")
        } else {
            $("#star0").attr("class", "star off")
        }
    } else {
        // error?
    }
}


function change_tags(tags) {
    var text = this.value;
    var uri = document.location + "";

    $.get("/ajax.xqy", {
        "action" : "tags",
        "tags"   : text,
        "book"   : uri
    }, confirmTags);
}

function confirmTags(data) {
    var tags = data.getElementsByTagName("tags");

    if (tags.length > 0) {
        tags = $(tags[0]).text();
        console.log("tags:" + tags);
        $("#tags").val(tags);
    }
}

$(document).ready(function(){
    $("#star0").click(change_stars);
    $("#star2").click(change_stars);
    $("#star3").click(change_stars);
    $("#star4").click(change_stars);
    $("#star5").click(change_stars);
    $("#tags").change(change_tags);
});
