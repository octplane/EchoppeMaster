
var form_id="#create";
var admin_email="#email";
var admin_email_cookie = "admin_email";

$(document).ready(function() {
	if($.cookie(admin_email_cookie) !== null) {
		$(admin_email).attr("value", $.cookie(admin_email_cookie));
	} else {
		$(admin_email).attr("value", "pouet");	
	}
});

$(form_id).submit(function() {
	$.cookie(admin_email_cookie, $(admin_email).attr("value"), { expires: 1515, path: '/' });
})
