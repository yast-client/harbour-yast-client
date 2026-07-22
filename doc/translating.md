# Translating Guide

You can translate YAST using Qt Linguist or by manually copying and editing an existing `.ts` file.

While not forced, it's highly recommended to check the [official Telegram translations platform](https://translations.telegram.org/) for more information on making the strings as smooth as possible in terms of language.

## Extra resource links

The About page in YAST includes links to useful SailfishOS-related resources such as the Fan Club group, News Network channel and others. Additionally, YAST allows translators to add extra localized resources to it for other languages. Currently, it's possible to add up to two of them. Note that it's not required to specify all or any extra resource links. Leave all or the remaining strings empty or unfinished if so.

To add additional localized resources, find the translation strings with the source starting with "extra_resource_". For each extra resource, a button is created on the About page. Each resource link has two strings, title and link path. Title is the name of the link and will be shown on the button. Link path is the suffix of the link to use. It will be prepended with the `https://t.me/` URL. It can be a username of a group or a channel, such as `MySailfishOSGroup` or `MySailfishOSChannel`, a invite link token like `+b0MjEF6g39BhMzQy` or any other supported Telegram link.
