# Pickup & Packing Planner

A single-page tool that turns an equipment order into an exact list of physical boxes, recommends **one** vehicle a customer should bring for local pickup, and produces a clean packing list for freight forwarders and returns vendors.

> **Portfolio version.** I designed and built this for the customer-support and warehouse teams at a home and commercial gym-equipment company. This public copy runs on a **fictional sample catalog**. Every product, SKU, dimension and order here is made up, and no company data, branding or customer information is included.

**Try it:** open `(https://pickuppackingplanner.vercel.app/)` in any browser. Then click **"load a sample order"** in the Order panel.

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
| **3D load preview** | The recommended vehicle in 3D: car, SUV, pickup, cargo van, box truck, or a truck pulling a trailer when the load outgrows a box truck. Every box is packed into the cargo area to true scale (1 unit = 1 inch), next to a 6 ft person for reference. The vehicle grows into the next size as items are added. Drag to rotate, scroll to zoom, hover a box for its SKU and size. Boxes that won't fit are laid out beside the vehicle. Falls back to a 2D truck on devices without WebGL. |
| **Outputs** | Copyable packing list (grouped by product, or a flat boxes-only list for freight forwarders). **Download PDF** (a real .pdf for email, with an "Include load image" option) plus Print. lb↔kg and in↔cm toggles that apply everywhere. **One-click copy of any single length, width, height or weight** for carrier forms. |

## Design decisions
- **Conservative by default.** A wasted trip costs far more than suggesting a bigger vehicle, so every limit is padded: brochure numbers trimmed, volume capped at 65% because boxes never pack perfectly, and no diagonal-fit assumptions. All values live in one commented `VEHICLE_CONFIG` block that a non-developer can edit.
- **Show the vehicle, not just name it.** A customer told to bring a cargo van, who can see the load packed into one next to a person, is far more likely to bring the right vehicle than one who just reads it. The 3D model always matches the recommendation, so the picture and the text never disagree.
- **Never guess data.** Items with missing dimensions are shown and flagged, not estimated. Unknown SKUs go to a "Not found" list, and 0-quantity lines go to "Skipped."
- **Exact SKUs on the paperwork.** Colors merge in *search* to cut clutter, but the order line keeps the exact color SKU, so packing lists for vendors stay correct.
- **Built for adoption.** It mirrors the Shopify picker staff already use, uses plain-language labels with no internal jargon, and keeps the review step on every import because OCR and PDFs can be messy.
- **Zero infrastructure.** One HTML file, with no backend, no build tooling, and no browser storage. three.js loads from a CDN; pdf.js, Tesseract and jsPDF load only when needed. The data is plain JS objects generated from ERP saved-search exports, and a "How to update this tool" guide is written into the source.
- **Privacy.** No prices, addresses or customer details are read into, shown in, or exported from the tool. It works with SKUs, quantities, dimensions and weights only.

## How it's built
- **Vanilla HTML/CSS/JS** in one file (`app.html`). `build.sh` inlines `data.js` (items and bundles) and `catalog.js` (categories and popular items) into `site/index.html`.
- **Product grouping:** a small rules table (`PRODUCT_RULES`, `FAMILY_RULES`) claims SKUs by pattern and writes Shopify-style option labels. Everything else is grouped automatically from catalog names, and colors are merged when box sizes match to the inch and weights to within ~5 lb.
- **Document parsing:** PDF text is rebuilt into lines by position. Packing-slip quantities sit beside the item block, so each "X of Y" is matched to the nearest SKU line by vertical distance. Photos go through OCR, with forgiveness for common misreads (O/0, I/1).
- **Vehicle logic:** pure functions over the box list (`compute`, `recommend`, `checkVehicle`).
- **3D view:** three.js. Each vehicle is a side profile (hood, raked windshield, roof line, wheel arches) extruded with rounded edges, wrapped in a custom Fresnel "x-ray glass" shader so the body reads as solid at the edges while the load stays visible. Tinted windows, 5-spoke wheels, lights, bumpers, mirrors and a soft contact shadow add realism. A heightmap packer on a 4-inch floor grid tries 6 orientations per box, flattest first, filling bottom-up and front-to-back. It packs 100+ boxes in about 20 ms. The scene only redraws while something moves.
- **PDF:** jsPDF builds a Letter-size packing list (logo, order #, vehicle summary, optional 3D snapshot, a table that continues across pages, totals). It's about 50 KB with the image.

## In production (internal version)
The internal build runs on the company's full ERP export (~6,000 SKUs and ~1,600 bundles), is hosted on Netlify from a private repo, and has a companion **Claude Project**. That project uses the same rules, so staff can give an AI assistant a sales-order number and get the box list, vehicle recommendation and a prefill link back, through the ERP's MCP connector.

## Repo layout
```
app.html      source (app code, vehicle config, product rules)
data.js       ITEMS + BUNDLES (sample data)
catalog.js    CATALOG: category / family / display name (sample data)
build.sh      builds site/index.html
site/         deployable page (vercel.json / netlify.toml publish this folder)
```
