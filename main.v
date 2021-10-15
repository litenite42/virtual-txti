import vweb
import mysql
import models
import zztkm.vdotenv as denv
import os
import json
import strings
import rand
import time
import strconv
import markdown

const (
	cnxn_settings = load_env()
)

struct DbSettings {
	uname    string
	dbname   string
	password string
}

struct App {
	vweb.Context
pub mut:
	cnxn mysql.Connection
}

fn load_env() DbSettings {
	denv.load()

	return DbSettings{
		uname: os.getenv('USER_NAME')
		dbname: os.getenv('DB_NAME')
		password: os.getenv('PASSWORD')
	}
}

fn (mut app App) init_cnxn() {
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
	vweb.run(app, 8082)
}

fn (mut app App) index() vweb.Result {
	return $vweb.html()
}

['/edit']
pub fn (mut app App) edit() vweb.Result {
	uuid := app.query['q']
	app.init_cnxn()
	mut connection := app.cnxn

	connection.connect() or { panic(err) }

	get_page_info := connection.query("SELECT wp.* from WebPages wp where wp.Guid = '$uuid'") or {
		panic(err)
	}
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
	html_text := vweb.RawHtml(markdown.to_html(webpage.content))
	return $vweb.html()
}

['/submit'; post]
pub fn (mut app App) submit_content() vweb.Result {
	app.init_cnxn()
	form := app.form.clone()

	mut web_page := models.map_to_page(form)

	submit_mode := form['submit-content']

	table := 'WebPages'
	mut query := strings.new_builder(100)
	now := time.now()
	mut connection := app.cnxn
	connection.connect() or { panic(err) }

	match submit_mode {
		'create' {
			if web_page.edit_code == models.default_guid || web_page.edit_code.len == 0 {
				guid := rand.uuid_v4()
				start_ndx := guid.len - 8

				web_page.edit_code = guid[start_ndx..guid.len]
			}
			query.write_string('INSERT INTO $table (Title, Content,SubmittedBy,SubmittedOn,EditCode) Values (')
			query.write_string("'")
			query.write_string(connection.escape_string(web_page.title))
			query.write_string("'")
			query.write_string(',')
			query.write_string("'")
			query.write_string(connection.escape_string(web_page.content))
			query.write_string("'")
			query.write_string(',')
			query.write_string("'")
			query.write_string(connection.escape_string(web_page.submitted_by))
			query.write_string("'")
			query.write_string(',')
			query.write_string("'")
			query.write_string(connection.escape_string(now.format()))
			query.write_string("'")
			query.write_string(',')
			query.write_string("'")
			query.write_string(connection.escape_string(web_page.edit_code))
			query.write_string("'")
			query.write_string(');')
		}
		'edit' {
			get_page_info := connection.query('SELECT wp.* from WebPages wp where wp.id = $web_page.id') or {
				panic(err)
			}
			mut db_entry := &models.WebPage{}
			// Get the result as maps
			for page in get_page_info.maps() {
				// Access the name of user
				db_entry = models.map_to_page(page)
			}
			println(web_page.edit_code)
			if web_page.edit_code != db_entry.edit_code {
				return app.text('Error: Invalid Edit Code')
			}

			edit_time := time.now()

			query.write_string('UPDATE $table\n')
			query.write_string('set\n')
			query.write_string("Content = '${connection.escape_string(web_page.content)}',\n")
			query.write_string("EditedBy = '${connection.escape_string(web_page.edited_by)}',\n")
			query.write_string("EditedOn = '${connection.escape_string(edit_time.format())}'\n")
			query.write_string('where Id = $web_page.id')
		}
		else {}
	}

	query_stmt := query.str()
	connection.query(query_stmt) or { panic(err) }

	mut id := 0
	mut result := '' // app.not_found()
	if submit_mode == 'create' {
		val := connection.last_id()
		if val is int {
			id = int(val)
			site_result := connection.query('select guid from WebPages where id = $id') or { panic(err) }
			site := site_result.maps()[0]
			uuid := site['guid']
			return app.json('{"key": "$uuid" }')
		}
	} else {
		result = '/details?q=$web_page.guid}'
	}

	return app.redirect(result) // app.details()
}

struct ShortSite {
	title     string
	edit_code string
	guid      string
	html_text string
}

pub fn (mut app App) site_details() vweb.Result {
	app.init_cnxn()
	mut connection := app.cnxn
	mut query := 'SELECT wp.Title, wp.Content, wp.EditCode, wp.Guid from WebPages wp where '

	connection.connect() or { panic(err) }
	if 'id' in app.query {
		str_id := app.query['id']
		id := strconv.atoi(str_id) or { return app.text('Error: Invalid Id entered.') }
		query += 'wp.Id = $id'
	} else {
		uuid := app.query['q']
		query += "wp.Guid = '$uuid'"
	}

	get_page_info := connection.query(query) or { panic(err) }
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

	html_text := vweb.RawHtml(markdown.to_html(webpage.content))

	x := ShortSite{
		title: webpage.title
		edit_code: webpage.edit_code
		guid: webpage.guid
		html_text: html_text
	}

	return app.json(json.encode(x))
}

pub fn (mut app App) created() vweb.Result {
	return $vweb.html()
}

pub fn (mut app App) details() vweb.Result {
	app.init_cnxn()
	mut connection := app.cnxn
	mut query := 'SELECT wp.Title, wp.Content from WebPages wp where '
	connection.connect() or { panic(err) }
	if 'id' in app.query {
		str_id := app.query['id']
		id := strconv.atoi(str_id) or { return app.text('Error: Invalid Id entered.') }
		query += 'wp.Id = $id'
	} else {
		uuid := app.query['q']
		query += "wp.Guid = '$uuid'"
	}

	get_page_info := connection.query(query) or { panic(err) }
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

	html_text := vweb.RawHtml(markdown.to_html(webpage.content))
	return $vweb.html()
}
