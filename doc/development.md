# Development notes

## Code Styling

In Fernschreiber, the code styling is very mixed. In Ferniegram, it can be mixed too. If it will not be abandoned by me, I will probably fix it later anyways.

## Message types

Completed (may not always be up-to-date):

- messageAnimatedEmoji
- messageAnimation
- messageChatChangeTitle
- messageExpiredVideo
- messageGiveawayCreated
- messageContactRegistered
- messageChatBoost
- messageChatAddMembers
- messageChatDeletePhoto
- messagePinMessage
- messageUnsupported
- messageLocation
- messageGame
- messageChatUpgradeTo
- messageChatUpgradeFrom
- messageDocument
- messageText
- messageSticker
- messageBotWriteAccessAllowed
- messageCustomServiceAction
- messageGiveawayCompleted
- messageVideoNote
- messageChatChangePhoto
- messageGift
- messageVoiceNote
- messageChatJoinByLink
- messageExpiredVideoNote
- messageGameScore
- messagePoll
- messageChatSetMessageAutoDeleteTime
- messageScreenshotTaken
- messageVideo
- messageVenue
- messagePhoto
- messageExpiredPhoto
- messageExpiredVoiceNote
- messageSupergroupChatCreate
- messageBasicGroupChatCreate
- messageChatDeleteMember
- messageAudio

Not yet finished (by the state of TDLib 1.8.46):

- messageCall
- messageChatJoinByRequest
- messageChatSetBackground
- messageChatSetTheme
- messageChatShared
- messageContact
- messageDice
- messageForumTopicCreated
- messageForumTopicEdited
- messageForumTopicIsClosedToggled
- messageForumTopicIsHiddenToggled
- messageGiftedPremium
- messageGiftedStars
- messageGiveaway
- messageGiveawayPrizeStars
- messageGiveawayWinners
- messageInviteVideoChatParticipants
- messageInvoice
- messagePaidMedia
- messagePassportDataReceived
- messagePassportDataSent
- messagePaymentRefunded
- messagePaymentSuccessful
- messagePaymentSuccessfulBot
- messagePremiumGiftCode
- messageProximityAlertTriggered
- messageRefundedUpgradedGift
- messageStory
- messageSuggestProfilePhoto
- messageUpgradedGift
- messageUsersShared
- messageVideoChatEnded
- messageVideoChatScheduled
- messageVideoChatStarted
- messageWebAppDataReceived
- messageWebAppDataSent

## Some notes

- setMessageProperties could probably be implemented better. Currently it is hardcoded in several places, including new message success callback. It is also not same as other set* chat list functions, others simply scrap data from the message, but this one sends a tdlib request. Not sure if this should also be added to handleMessageContentUpdated, handleMessageEditedUpdated or anything similar. Probably not, but who knows

## Message entity types

Implemented types (may be out of date):

- textEntityTypeCode
- textEntityTypePhoneNumber
- textEntityTypePreCode
- textEntityTypeBold
- textEntityTypeBotCommand
- textEntityTypePre
- textEntityTypeStrikethrough
- textEntityTypeMention
- textEntityTypeTextUrl
- textEntityTypeMentionName
- textEntityTypeUrl
- textEntityTypeItalic
- textEntityTypeUnderline
- textEntityTypeEmailAddress

Not yet finished (by the state of TDLib 1.8.46):

- textEntityTypeBankCardNumber
- textEntityTypeBlockQuote
- textEntityTypeExpandableBlockQuote
- textEntityTypeCashtag
- textEntityTypeCustomEmoji
- textEntityTypeHashtag
- textEntityTypeMediaTimestamp
- textEntityTypeSpoiler