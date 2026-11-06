# Google Play — Content rating questionnaire

Play Console → App content → Content rating → **Start questionnaire**.

## Category

Choose **Utility, Productivity, Communication, or Other** (the app is a
counting/ledger utility). Do not choose a game category.

## Answers

| Question | Answer |
| --- | --- |
| Violence (realistic, fantasy, or cartoon) | **No** |
| Blood, gore, or injury detail | **No** |
| Sexual content or nudity | **No** |
| Suggestive content | **No** |
| Profanity or crude language | **No** |
| References to drugs, alcohol, or tobacco | **No** |
| Gambling or simulated gambling | **No** |
| Horror or fear elements | **No** |
| User-generated content or social features | **No** |
| Users can interact or share content with others | **No** (the OS share sheet sends a file the user chooses; there is no in-app social feed, chat, or user content) |
| Location sharing | **No** |
| Users can purchase digital goods | **No** |
| Contains ads | **No** |
| App is a web browser or search engine | **No** |
| App is a news app | **No** |
| App provides medical/health information | **No** |
| App provides financial or investment advice | **No** (it counts cash; it does not advise or execute transactions) |
| App facilitates real-money gambling | **No** |
| App contains crypto mining | **No** |
| App collects or shares personal data | **No** (see `DATA_SAFETY.md`) |

## Expected result

The questionnaire should produce:

- **Google Play rating:** Everyone
- **ESRB:** Everyone
- **PEGI:** 3
- **USK:** 0
- **ClassInd:** Livre (L)

Play computes the final rating; the values above are the expected outcome for
these answers, not a guarantee.

## Survey-specific notes

- The app displays the Bangladeshi taka symbol and images of Bangladeshi
  banknotes/coins as **stylised illustrations**. There is no real currency
  scanning, no camera use, and no copyrighted note artwork.
- The voucher and Excel exports contain only the user's own counting data.
- No external links are shown to users except the Play Store rating page and
  the device email app for feedback. There is no browser inside the app.
- Haptics and themes do not affect the rating.
