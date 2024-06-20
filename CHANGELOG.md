## Changelog

### 7.3
Make commands work on user installs.

### 7.0
Added paper as the new default and changed the bot into a general purpose YuGiOh bot instead of just Masterduel.

### 6.0
Added the ability to parse `<card name>` from messages with a right click menu option.

### 5.0

Added OCG art option to the art command with `ocg:true`, which requires a donation over on [Ko-Fi](https://ko-fi.com/okkkk).\
Ko-Fi triggers a webhook and sends the donation info to [Bonk](https://github.com/okkdev/bonk) which is a microservice that parses the user id included in the donation message and saves it in a database.

### 4.0

Added `/art` command. This command embeds card artwork. The art is dumped directly from Master Duel then upscaled using Waifu2x and uploaded to an s3 bucket.

### 3.0

Implemented a fuzzy searching algorithm.\
Cardian now generates an index ETS table of shared trigrams in all card names. The search querie trigrams are pulled from the index and the matching cards are sorted by occurence of trigrams.

### 2.0

Refactored how cards are fetched. In v1.0 every autocomplete query and card request were sent to the Master Duel Meta API. This was slow and, especially the autocomplete requests, very wasteful.\
With v2.0 the bot fetches all cards every 2 hours (by default, can be set via env var) and caches them in an ETS. Now all data is fetched from the cache. This is way faster, fixing the time-out of autocompletion responses.

