import Ubuntu.OnlineAccounts.Plugin 1.0
import "." as Local

OAuthMain
{
  creationComponent: Local.OAuth {
    webViewPreferences: {"localStorageEnabled": true}

    function completeCreation(reply)
    {
      var xhr = new XMLHttpRequest()
      xhr.open("GET", "https://api.pushbullet.com/v2/users/me", true)
      xhr.setRequestHeader("Authorization", "Bearer " + reply.AccessToken)
      xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE)
        {
          if (xhr.status == 200)
          {
            var user = JSON.parse(xhr.responseText);
            account.updateDisplayName(user.name ? user.name : user.email)
          }
          else
          {
            console.log("error: " + xhr.status)
          }

          account.synced.connect(finished)
          account.sync()
        }
      };

      xhr.send()
    }
  }
}
