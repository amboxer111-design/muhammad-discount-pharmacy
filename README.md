# Muhammad Discount Pharmacy - Chakdara

A Flutter inventory and billing app for the pharmacy. The shop name includes
“Discount”; the app never applies a fixed or automatic discount.

## Features

- Medicine inventory with name, company, category, price, stock, expiry date,
  and rack number.
- Search by medicine name, category filters, and low-stock / expiry indicators.
- Cart billing at the medicines’ original listed prices.
- Optional admin-entered manual discount, validated from 0% through 2%, with a
  default of 0%.
- Printable PDF bills showing the shop name, configured address and phone,
  item prices, subtotal, any explicitly entered discount, and total due.
- Local persistence for inventory and shop contact details.

The address and phone number start unset because no verified contact details
were available. Enter the correct values under **Settings** before printing
bills; unset values print as “Address not set” and “Phone not set”.

## Run

```sh
flutter pub get
flutter run
```

Run the automated tests and analyzer with:

```sh
flutter test
flutter analyze
```
