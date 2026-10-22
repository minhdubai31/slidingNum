# Slide Puzzle privacy policy

Status: publisher confirmed on 2026-10-22. Public name: MinC. Support/privacy email: trahoangminh31@gmail.com.

Public page: https://slide-puzzle-backend.vercel.app/privacy/

The published HTML is in `backend/public/privacy/index.html`. The original template is retained here for future updates.

Never publish the template with placeholder contact details. To update the page, HTML-escape and substitute `{{PUBLISHER_NAME}}` and `{{CONTACT_EMAIL}}`, then write `backend/public/privacy/index.html` and deploy the backend. Add the public URL to the Play Console listing. The app Settings link already targets that route.

Scope verified against current code: local player profile and saved games; system-selected image copies and cache; no player photo upload; public catalogue/background requests over HTTPS; Vercel and Supabase hosting; browser IndexedDB content cache; admin sessionStorage and unsaved preview drafts; no player account, ads, behavioural analytics or IAP integration found. Clear Game Data preserves language/public asset cache and may not remove the Android picker's temporary cache copy, so the policy also explains system-level storage deletion.

No fixed third-party log-retention period or audience age has been invented. Recheck the production provider settings, third-party SDKs, target audience and Play Console Data safety answers before store submission.

References checked on 2026-10-22:
- Google Play User Data: https://support.google.com/googleplay/android-developer/answer/10144311?hl=en
- Vercel Privacy Notice: https://vercel.com/legal/privacy-notice
- Supabase Privacy Policy: https://supabase.com/privacy
