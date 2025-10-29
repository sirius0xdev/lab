admins = { "sirius@sirius-sec.com" }

modules_enabled = {

		"disco";
		"roster";
		"saslauth";
		"tls";

		"blocklist";
		"bookmarks";
		"carbons";
		"dialback";
		"limits";
		"pep";
		"private";
		"smacks"; 
		"vcard4"; 
		"vcard_legacy"; 

		"account_activity"; 
		"cloud_notify"; 
		"csi_simple";
		"invites"; 
		"invites_adhoc"; 
		"invites_register"; 
		"ping"; 
		"register"; 
		"time"; 
		"uptime";
  	"version"; 

		"admin_adhoc"; 
		"admin_shell";

		"proxy65"; 		
	  "s2s_bidi";

		"watchregistrations"; 
}



modules_disabled = {
	 "offline"; 
}



s2s_secure_auth = true


limits = {
	c2s = {
		rate = "10kb/s";
	};
	s2sin = {
		rate = "30kb/s";
	};
}


authentication = "internal_hashed"



log = {
	info = "*syslog"; -- Uncomment this for logging to syslog
}


certificates = "certs"


VirtualHost "localhost"



