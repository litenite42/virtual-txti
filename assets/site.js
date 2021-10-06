toggle = function (el) {
    let data = el.dataset;

    if (data.target) {
        let targets = document.querySelectorAll(data.target);
        for (let target of targets) {
            if (target.style.display == 'none') {
                target.style.display = 'block';
            }
            else {
                target.style.display = 'none';
            }
        }
    }
}