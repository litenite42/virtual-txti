module models

import time
import strconv

pub const (
	default_guid = '0000000000'
)
[table: 'WebPages']
pub struct WebPage {
pub mut:
	id           int [primary; sql: serial]
	title        string [sql: 'Title']
	content      string [sql: 'Content']
	submitted_by string [sql: 'SubmittedBy']
	submitted_on time.Time [sql: 'SubmittedOn']
	edited_by    string [sql: 'EditedBy']
	edited_on    time.Time [sql: 'EditedOn']
	edit_code    string [sql: 'EditCode']
	guid         string [sql: 'Guid']
}

pub fn map_to_page(result map[string]string) &WebPage {
	submit_time := time.parse(result['SubmittedOn']) or { time.unix(0) }
	edit_time := time.parse(result['EditedOn']) or { time.unix(0) }
	return &WebPage{
		id: if 'Id' in result { result['Id'].int() } else { -1 }
		title: if 'Title' in result { result['Title'] } else { 'Virtual Txti' }
		content: if 'Content' in result { result['Content'] } else { '' }
		submitted_by: if 'SubmittedBy' in result { result['SubmittedBy'] } else { 'anon' }
		submitted_on: submit_time // if 'SubmittedOn' in result { result['SubmittedOn'] } else
		edited_by: if 'EditedBy' in result { result['EditedBy'] } else { '' }
		edited_on: edit_time
		edit_code: if 'EditCode' in result { result['EditCode'] } else { models.default_guid }
		guid: if 'Guid' in result { result['Guid'] } else { models.default_guid }
	}
}
