const $ = document.querySelector.bind(document),
$$ = document.querySelectorAll.bind(document);

if (sessionStorage.getItem('created.key')) {
    let createdId = sessionStorage.getItem('created.key')
    console.log(createdId)
    let formData = new FormData();
    formData.append('id', createdId)
    fetch('/site_details?id='+createdId).then(r => r.json()).then(data => {
        let guidTexts = $$('.guid-text'),
            editCode = $('#edit-code'),
            editLink = $('#edit-link'),
            htmlText = $('#html-text');

        for (let guidText of guidTexts) {
            guidText.innerHTML = data.guid;
            guidText.textContent = data.guid;
        }

        editCode.innerHTML = data.edit_code;
        editCode.textContent = data.edit_code;

        let editAnchor = document.createElement('a');
        editAnchor.href = '/edit?q='+data.guid
        editAnchor.text = 'here';

        editLink.appendChild(editAnchor);

        htmlText.innerHTML = data.html_text;
    })
}