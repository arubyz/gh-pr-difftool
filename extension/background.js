const code = `
    void function ()
    {
        const elements = document.getElementsByTagName("*");
        const regex = new RegExp("Recent Commits to [^:]+:(.*)");
        var found = false;
        for (var i = 0; i < elements.length; i++)
        {
            const match = regex.exec(elements[i].title)
            if (match != null)
            {
                const parts = window.location.pathname.split("/");
                const user = parts[1];
                const repo = parts[2];
                const branch = match[1];
                chrome.runtime.sendMessage({ user, repo, branch });
                found = true;
                break;
            }
        }
        if (!found)
        {
            chrome.runtime.sendMessage({});
        }
    }();
    `;

chrome.runtime.onMessage.addListener(
    function(request, sender, sendResponse)
    {
        if (request.user && request.repo && request.branch)
        {
            const url = "prdiff://" + request.user + "/" + request.repo + "/" + request.branch;
            chrome.tabs.update({ url });
        }
        else
        {
            window.alert("Cannot determine PR branch. Is the current page a GitHub PR?");
        }
    });

chrome.browserAction.onClicked.addListener(function(tab)
{
    chrome.tabs.executeScript({ code });
});
