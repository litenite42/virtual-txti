module models

import time
import strconv

pub const (
	default_guid = '0000000000'
)

pub struct WebPage {
pub mut:
	id           int
	title        string
	content      string
	submitted_by string
	submitted_on time.Time
	edited_by    string
	edited_on    time.Time
	edit_code string
}

pub struct PageGuid {
	pub mut:
	page_id int
	detail_guid string
	edit_guid string
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
		edit_code: if 'EditCode' in result { result['EditCode'] } else { default_guid }
	}
}

pub fn map_to_guids(result map[string]string) ?&PageGuid {
	id := if 'PageId' in result { strconv.atoi(result['PageId']) or { -1 } } else {-1}
	detail_guid := if 'DetailGuid' in result { result['DetailGuid'] }  else { '' }
	edit_guid := if 'EditGuid' in result { result['EditGuid'] }  else { '' }

	if id == -1 {
		return error_with_code('Invalid Page Id.', 1)
	} if default_guid == '' {
		return error_with_code('Invalid Detail Guid.', 2)
	} if edit_guid == '' {
		return error_with_code('Invalid Detail Guid.', 3)
	}
	return &PageGuid {
		page_id : id
		detail_guid : detail_guid
		edit_guid : edit_guid
	}
}
