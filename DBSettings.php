<?php
class DatabaseSettings
{
	var $settings;
	function getSettings()
	{
		// Database variables
		// Host name
		$settings['dbhost'] = 'localhost';
		// Database name
		$settings['dbname'] = 'local-sad';
		// Username
		$settings['dbusername'] = 'usersad';
		// Password
		$settings['dbpassword'] = 'password';

		$settings['offset'] = 1;

		return $settings;
	}
}
