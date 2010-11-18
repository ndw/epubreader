/* part.js */

function setIFrameSize(event) {
    var iframe = $("#epub-iframe");

    var docheight = $(document).height();
    var hdrheight = $("#epub-header").height();
    var ftrheight = $("#barwrapper").height();

    var space = hdrheight + ftrheight + 40;

    /*
    console.log("docheight: " + docheight);
    console.log("hdrheight: " + hdrheight);
    console.log("ftrheight: " + ftrheight);
    console.log("space    : " + space);
    console.log("iframe   : " + (docheight - space));
    */

    if (iframe.length > 0) {
        iframe.height(docheight - space);
    } else {
        var src = document.location + ""; // Turn URI into string!
        idx = src.indexOf("#");
        if (idx >= 0) {
            var hash = src.substr(idx);
            src = src.substr(0, idx);
            src += ",raw" + hash;
        } else {
            src += ",raw";
        }

        var e = "<iframe id='epub-iframe' frameborder='0' width='100%' ";
        e += "src='" + src + "'/>";

        $("#iframe-wrapper").html(e);

        var iframe = $("#epub-iframe");
        iframe.height(docheight - space);
    }
}

$(document).ready(function(){
    $(window).resize(setIFrameSize);
    $(window).resize();

    var cur = $("#curplay").val();
    var max = $("#maxplay").val();
    var pval = cur / max * 100;

    $("#progressbar").progressbar({ value: pval });

});
