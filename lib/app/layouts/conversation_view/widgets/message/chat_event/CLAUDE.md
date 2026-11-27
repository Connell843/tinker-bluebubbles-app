# widgets/message/chat_event/ — System / Chat Event Messages

## Files
| File | Purpose |
|------|---------|
| `chat_event.dart` | Renders system-generated chat event rows (member added/removed, name changed, group photo changed, video/audio call started, etc.) |

## Unsent messages
An unsent part renders here as "X unsent a message". Holding it opens Message Info, which puts what the part said (`Message.unsentTextForPart`, from `UnsentContent`) above the raw data when a copy was kept.

## Usage
Rendered instead of a normal message bubble when `message.isGroupAction == true` or `message.itemType != 0`.

## Styling
Centered, muted text without a bubble tail. Uses `context.theme.textTheme.bodySmall` with reduced opacity.

## Related
- Message routing: `../message_holder.dart` (decides chat_event vs normal bubble)
- DB model: `lib/database/io/message.dart` — `itemType`, `groupActionType`, `groupTitle`
