# Delete Your StudyBook AI Account - Final Public Draft

Status: `PRODUCT OWNER CONTENT APPROVED - FINAL PUBLICATION APPROVAL PENDING`

Public path: `https://studybookai.com/account-deletion`

Operator: `Welinton Rafael Mejía González`

Monitored contact: `studybookaiapp@gmail.com`

Professional contact address: `Bufete Jurídico “MULTISERVICIOS ZORRILLA”, Avenida Sabana Larga, núm. 148, Ensanche Ozama, Santo Domingo Este, República Dominicana`. This is a professional contact domicile only and does not change the legal operator.

Effective date: pending the actual final publication date.

The integrated public text is maintained in
`web/marketing/src/app/account-deletion/page.tsx` and remains page-level
`noindex`.

## In-App Process

1. Sign in to StudyBook AI.
2. Open Cuenta.
3. Select `Eliminar mi cuenta`.
4. Reauthenticate when requested and enter the required confirmation phrase.
5. Confirm permanent deletion.

The app reports completion only after the backend workflow succeeds. A partial
failure is reported for retry and is not presented as completed deletion.

## Assistance Without App Access

The approved monitored contact can provide assistance when a user cannot
access the app. A plain message or email address is not sufficient authority to
delete an account. Reasonable account-control verification is required before
execution. Users must not send passwords, access codes or private documents by
email.

## Scope And Timing

The backend inventories known owner-scoped Auth, subscription mapping,
documents, private Storage, RAG chunks, generated results, chats, AudioBooks,
certificates, Teacher data and usage records. It removes Auth last.

After a valid request, active-system deletion or anonymization has a maximum
operational target of 30 days. Residual backup copies may remain for up to 90
days. Records strictly necessary for security, fraud prevention, legal,
accounting, tax, dispute or defense-of-rights purposes may remain for the
legitimately required period.

Account deletion does not itself cancel Stripe, Google Play or another
external subscription. The user must manage billing through the original
provider.

## Remaining Publication Decisions

- Effective date: set only at final publication approval.
- Final publication authorization: pending.

Public indexing remains disabled.
