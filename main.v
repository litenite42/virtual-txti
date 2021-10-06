import vweb
import mysql
import models
import zztkm.vdotenv as denv
import os

const (
	cnxn_settings = load_env()
)

struct DbSettings {
	uname string
	dbname string
	password string
}

struct App {
	vweb.Context
pub mut:
	cnxn mysql.Connection
}

fn load_env() DbSettings {
	denv.load()

	return DbSettings {
		uname : os.getenv('USER_NAME')
		dbname : os.getenv('DB_NAME')
		password : os.getenv('PASSWORD')
	}
}

fn (mut app App) init_cnxn()  {
	app.cnxn = mysql.Connection{
			username: cnxn_settings.uname
			dbname: cnxn_settings.dbname
			password: cnxn_settings.password
		}
}

pub fn init_app() &App {
	mut app := &App{}
	
	app.init_cnxn()
	return app
}

fn main() {
	mut app := init_app()
	// Automatically make available known static mime types found in given directory.
	app.handle_static('assets', true)
	vweb.run(&App{}, 8082)
}

pub fn (mut app App) index() vweb.Result {
	return $vweb.html()
}

["/edit"]
pub fn (mut app App) edit() vweb.Result {
	uuid := app.query['q']
	println('hello $uuid')
	app.init_cnxn()
		mut connection := app.cnxn
		
		connection.connect() or { panic(err) }
		// Change the default database
		// connection.select_db('db_users') ?
		// Do a query
		get_page_info := connection.query("SELECT * from WebPages where Guid = '$uuid'") or { panic(err) }
		mut webpage := &models.WebPage{}
		// Get the result as maps
		for page in get_page_info.maps() {
			// Access the name of user
			webpage = models.map_to_page(page)
		}
		defer {
		unsafe {
			// Free the query result
			get_page_info.free()
		}
		}
		// Close the connection if needed
		connection.close()


	return $vweb.html()
}

['/submit'; post]
pub fn (mut app App) submit_content() vweb.Result {
	app.init_cnxn()
	site_content := app.form['site_content']
	println(site_content)
	// println(app)

	return app.text('Ok')
}
