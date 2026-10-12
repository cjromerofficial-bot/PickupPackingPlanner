# Pickup & Packing Planner

A single-page tool that turns an equipment order into an exact list of physical boxes, recommends **one** vehicle a customer should bring for local pickup, and produces a clean packing list for freight forwarders and returns vendors.

> **Portfolio version.** I designed and built this for the customer-support and warehouse teams at a home and commercial gym-equipment company. This public copy runs on a **fictional sample catalog**. Every product, SKU, dimension and order here is made up, and no company data, branding or customer information is included.

**Try it:** open `site/index.html` in any browser, or deploy the `site/` folder to any static host. Then click **"load a sample order"** in the Order panel, or **Import order → "Paste a sample packing slip"**.

---

## The problem
- **Wasted pickup trips.** Customers picking up gym equipment showed up in a sedan for an 86" upright or a 968 lb cable-machine crate. Staff had no quick, consistent way to say "bring a cargo van."
- **Bundles hide the real boxes.** One product on an order (e.g. a cable-tower attachment) ships as 4–17 separate boxes, each with its own size and weight. The order shows one line, but the dock sees a pallet.
- **Manual data entry for shipping.** Freight forwarders, a cross-border returns vendor and carrier label forms (like FedEx) need exact SKUs, dimensions and weights, often typed in one field at a time.
- **Data was scattered** across an ERP item export, a bundle/kit export, Shopify order pages, PDF packing slips, sales orders and return authorizations.

## What it does
| Area | Details |
|---|---|
| **Find products** | Search modeled on Shopify's "Select products" picker: one product with its options (`Pair / 80"`, `Set of 4 / 93"`). Matching is forgiving (`"cable tower"`, `rk7 cr`). Category filters. Popular items rank first. Color variants that ship in the same box collapse into one option, with color picked on the order line. |
| **Import orders** | Upload or paste **packing slips, sales orders, RMAs, Shopify draft orders**, as PDF (read with pdf.js) or **photo/screenshot** (in-browser OCR with Tesseract.js). Each format has its own parser: "X of Y" quantities, "Part of:" grouping, discount and return-shipping lines skipped, a sales order and slips for the same order not double-counted. Everything lands in an editable review list before it's added. |
| **Prefill links** | `?order=SO1001&items=SKU:qty,...` fills the order, so another system (or an AI assistant connected to the ERP) can hand staff a ready-made link. |
| **Boxes & totals** | Bundles expand into child boxes. Weights and dimensions come only from the boxes, never double-counted. Missing data is flagged "Dimensions unavailable — verify manually" and excluded instead of guessed. Boxes over 150 lb are tagged for staff loading assist. |
| **Vehicle recommendation** | Car → SUV → Pickup → Cargo Van → Box Truck. Picks the smallest vehicle that passes **all** checks: ≤75% of payload, ≤65% of cargo volume, longest box + 4" clearance, and every box fitting through the door opening. Explains in one line why each smaller vehicle was ruled out. |
| **Load preview** | An SVG rear view of an open box truck. Boxes drop in proportional to their real size, with a skyline packing layout, and stays smooth with 50+ boxes. Volume and weight bars are color-coded. |
| **Outputs** | Copyable packing list (grouped by product, or a flat boxes-only list for freight forwarders). Print / Save as PDF with order # and date. lb↔kg and in↔cm toggles that apply everywhere. **One-click copy of any single length, width, height or weight** for carrier forms. |

## Design decisions
- **Conservative by default.** A wasted trip costs far more than suggesting a bigger vehicle, so every limit is padded: brochure numbers trimmed, volume capped at 65% because boxes never pack perfectly, and no diagonal-fit assumptions. All values live in one commented `VEHICLE_CONFIG` block that a non-developer can edit.
- **Never guess data.** Items with missing dimensions are shown and flagged, not estimated. Unknown SKUs go to a "Not found" list, and 0-quantity lines go to "Skipped."
- **Exact SKUs on the paperwork.** Colors merge in *search* to cut clutter, but the order line keeps the exact color SKU, so packing lists for vendors stay correct.
- **Built for adoption.** It mirrors the Shopify picker staff already use, uses plain-language labels with no internal jargon, and keeps the review step on every import because OCR and PDFs can be messy.
- **Zero infrastructure.** One HTML file, with no backend, no build tooling, and no browser storage. pdf.js and Tesseract load from a CDN only when needed. The data is plain JS objects generated from ERP saved-search exports, and a "How to update this tool" guide is written into the source.
- **Privacy.** No prices, addresses or customer details are read into, shown in, or exported from the tool. It works with SKUs, quantities, dimensions and weights only.

## How it's built
- **Vanilla HTML/CSS/JS** in one file (`app.html`). `build.sh` inlines `data.js` (items and bundles) and `catalog.js` (categories and popular items) into `site/index.html`.
- **Product grouping:** a small rules table (`PRODUCT_RULES`, `FAMILY_RULES`) claims SKUs by pattern and writes Shopify-style option labels. Everything else is grouped automatically from catalog names, and colors are merged when box sizes match to the inch and weights to within ~5 lb.
- **Document parsing:** PDF text is rebuilt into lines by position. Packing-slip quantities sit beside the item block, so each "X of Y" is matched to the nearest SKU line by vertical distance. Photos go through OCR, with forgiveness for common misreads (O/0, I/1).
- **Vehicle logic:** pure functions over the box list (`compute`, `recommend`, `checkVehicle`).
- **Truck visual:** SVG with a 1-px skyline packer. Box areas scale with volume relative to the recommended vehicle, and CSS transitions animate the drops.

## In production (internal version)
The internal build runs on the company's full ERP export (~6,000 SKUs and ~1,600 bundles), is hosted on Netlify from a private repo, and has a companion **Claude Project**. That project uses the same rules, so staff can give an AI assistant a sales-order number and get the box list, vehicle recommendation and a prefill link back, through the ERP's MCP connector.

## Repo layout
```
app.html      source (app code, vehicle config, product rules)
data.js       ITEMS + BUNDLES (sample data)
catalog.js    CATALOG: category / family / display name (sample data)
build.sh      builds site/index.html
site/         deployable page
```
