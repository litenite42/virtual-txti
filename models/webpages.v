module models
import time
pub struct WebPage {
pub:
	id int
	title string
	content string
	guid string
	submitted_by string
	submitted_on time.Time
	edited_by string
	edited_on time.Time
	edit_code string
	detail_guid string
}

pub fn map_to_page(result map[string]string) &WebPage {
	submit_time := time.parse(result['SubmittedOn']) or {time.unix(0)}
	edit_time := time.parse(result['EditedOn']) or {time.unix(0)}
	return &WebPage {
		id : if 'Id' in result {result['Id'].int()} else { -1 }
		title : if 'Title' in result { result['Title'] } else { 'Virtual Txti' }
		content : if 'Content' in result { result['Content'] } else { '' }
		guid : if 'Guid' in result { result['Guid'] } else { '' }
		submitted_by : if 'SubmittedBy' in result { result['SubmittedBy'] } else { 'anon' }
		submitted_on : submit_time//if 'SubmittedOn' in result { result['SubmittedOn'] } else 
		edited_by : if 'EditedBy' in result { result['EditedBy']  } else {''}
		edited_on : edit_time
		edit_code : if 'EditCode' in result { result['EditCode'] } else { '0000000000' }
		detail_guid : if 'DetailGuid' in result { result['DetailGuid'] } else { '00000000' }
	}
}