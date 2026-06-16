# -*- coding: utf-8 -*-
"""
Diagram generator for the MediAI FYP report.
Produces clean, professional PNG diagrams using matplotlib (no extra deps).
All images are written into ./images relative to this file.
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Ellipse, Circle
from matplotlib.lines import Line2D

HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(HERE, "images")
os.makedirs(IMG, exist_ok=True)

# Colour palette
BLUE = "#1f6fb2"
BLUE_L = "#d6e8f5"
GREEN = "#2e8b57"
GREEN_L = "#d6efe1"
ORANGE = "#d2691e"
ORANGE_L = "#fbe6d4"
PURPLE = "#6a5acd"
PURPLE_L = "#e4e0f7"
GREY = "#555555"
GREY_L = "#ededed"
RED = "#b22222"
RED_L = "#f7d9d9"

plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "font.size": 9,
})


def _box(ax, x, y, w, h, text, fc, ec, fs=9, bold=False, tc="black"):
    box = FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.08",
                         linewidth=1.3, edgecolor=ec, facecolor=fc, zorder=2)
    ax.add_patch(box)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            fontsize=fs, fontweight="bold" if bold else "normal",
            wrap=True, zorder=3, color=tc)
    return (x, y, w, h)


def _arrow(ax, p1, p2, color=GREY, style="-|>", lw=1.4, ls="-", rad=0.0):
    a = FancyArrowPatch(p1, p2, arrowstyle=style, color=color, lw=lw,
                        mutation_scale=12, linestyle=ls,
                        connectionstyle=f"arc3,rad={rad}", zorder=1)
    ax.add_patch(a)


def _save(fig, name):
    path = os.path.join(IMG, name)
    fig.savefig(path, dpi=170, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("wrote", path)


# ─────────────────────────────────────────────────────────────────────────────
# 1. System Architecture (layered)
# ─────────────────────────────────────────────────────────────────────────────
def system_architecture():
    fig, ax = plt.subplots(figsize=(11, 9))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    # Presentation layer
    _box(ax, 2, 86, 96, 12, "", "#f3f8fc", BLUE)
    ax.text(4, 96.5, "PRESENTATION LAYER", fontsize=10, fontweight="bold", color=BLUE)
    _box(ax, 8, 87.5, 38, 7.5, "Customer Mobile App (Flutter)\nHome · Store · Cart · Checkout · Orders\nReminders · Stock · AI Chatbot · Profile",
         BLUE_L, BLUE, fs=8)
    _box(ax, 54, 87.5, 38, 7.5, "Web Admin Panel (Flutter Web)\nDashboard · Products · Orders · Customers\nBanners · Coupons · Prescriptions · Admins",
         GREEN_L, GREEN, fs=8)

    # Application layer
    _box(ax, 2, 64, 96, 18, "", "#fcfcf7", GREY)
    ax.text(4, 80.5, "APPLICATION LAYER  (GetX Controllers + Business Logic)", fontsize=10, fontweight="bold", color=GREY)
    _box(ax, 6, 66, 26, 11, "Mobile Controllers\nHome · Cart · Order\nProduct · Wishlist\nChatbot · Medication", GREY_L, GREY, fs=8)
    _box(ax, 37, 66, 26, 11, "Admin Controllers\nDashboard · Product\nOrder · Category\nBanner · Coupon", GREY_L, GREY, fs=8)
    _box(ax, 68, 66, 26, 11, "Business Logic\nAuth · Stock calc\nScheduling · Pricing\nDiscount · Reports", GREY_L, GREY, fs=8)

    # AI service layer
    _box(ax, 2, 44, 96, 17, "", "#faf7fc", PURPLE)
    ax.text(4, 59.5, "AI SERVICE LAYER  (FastAPI Backend — Python)", fontsize=10, fontweight="bold", color=PURPLE)
    _box(ax, 6, 46, 20, 11, "Chat / RAG API\n/chat · /chat/rag", PURPLE_L, PURPLE, fs=8)
    _box(ax, 28, 46, 20, 11, "Query Router &\nIntent Classifier", PURPLE_L, PURPLE, fs=8)
    _box(ax, 50, 46, 20, 11, "RAG Pipeline\nEmbed · Retrieve\nGroq LLM", PURPLE_L, PURPLE, fs=8)
    _box(ax, 72, 46, 22, 11, "Symptom Triage +\nCoupon Engine", PURPLE_L, PURPLE, fs=8)

    # Data layer
    _box(ax, 2, 16, 96, 25, "", "#fdf9f4", ORANGE)
    ax.text(4, 39.5, "DATA LAYER", fontsize=10, fontweight="bold", color=ORANGE)
    _box(ax, 6, 28, 26, 9, "Repository Pattern\nAuth · User · Product\nOrder · Category", ORANGE_L, ORANGE, fs=8)
    _box(ax, 6, 18, 26, 8, "Local Storage\nSQLite (medicines,\nalarms, queue) · GetStorage", "#eef7ef", GREEN, fs=8)
    _box(ax, 37, 18, 28, 19, "Firebase Cloud\n\nFirestore (Users, Products,\nOrders, Categories, Brands,\nBanners, Coupons, Admins)\n\nAuthentication\nStorage · Cloud Messaging", "#eaf3fb", BLUE, fs=8)
    _box(ax, 69, 18, 25, 19, "AI Knowledge Base\n\nChromaDB Vector Store\n(DailyMed + OpenFDA\nembeddings)\n\nPharma Index (RxNorm)\nbrand/generic/ingredient", PURPLE_L, PURPLE, fs=8)

    # Background services
    _box(ax, 2, 2, 96, 11, "", "#f7f7f7", GREY)
    ax.text(4, 11.5, "BACKGROUND SERVICES LAYER", fontsize=10, fontweight="bold", color=GREY)
    for i, t in enumerate(["Notification\nService", "Sync\nService", "Connectivity\nService", "Offline Queue\nService", "Stock Alert\n(WorkManager)"]):
        _box(ax, 5 + i * 18.6, 3, 16, 6, t, GREY_L, GREY, fs=8)

    # Arrows between layers
    for x in (27, 73):
        _arrow(ax, (x, 86), (x, 82), BLUE, lw=1.6)
        _arrow(ax, (x, 64), (x, 61), PURPLE, lw=1.6)
        _arrow(ax, (x, 44), (x, 41), ORANGE, lw=1.6)
    _arrow(ax, (50, 16), (50, 13), GREY, lw=1.6)
    # bidirectional sync local<->cloud
    _arrow(ax, (32, 22), (37, 22), GREEN, style="<|-|>", lw=1.8)
    ax.text(34.5, 23.2, "sync", fontsize=7, color=GREEN, ha="center")

    ax.set_title("Figure: MediAI Layered System Architecture", fontsize=11, fontweight="bold", pad=10)
    _save(fig, "fig_architecture.png")


# ─────────────────────────────────────────────────────────────────────────────
# 2. High-level component / system diagram (from the user's mermaid layout)
# ─────────────────────────────────────────────────────────────────────────────
def component_diagram():
    fig, ax = plt.subplots(figsize=(11, 8.5))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    # Frontend
    _box(ax, 28, 86, 44, 12, "", BLUE_L, BLUE)
    ax.text(50, 96, "Frontend Layer", ha="center", fontsize=10, fontweight="bold", color=BLUE)
    fe1 = _box(ax, 31, 87.5, 18, 7, "Admin Dashboard\n(Flutter Web)", "white", BLUE, fs=8)
    fe2 = _box(ax, 51, 87.5, 18, 7, "User Mobile App\n(Flutter)", "white", BLUE, fs=8)

    # Backend
    _box(ax, 4, 58, 92, 14, "", GREEN_L, GREEN)
    ax.text(50, 70.5, "Backend Layer (FastAPI / Firebase)", ha="center", fontsize=10, fontweight="bold", color=GREEN)
    bes = ["Chatbot API", "AI Interface\nConnector", "Medicine &\nOrder APIs", "Reminder &\nAuto-refill", "Auth\nHandler", "Prescription\n& OCR API", "Payment\nAPI"]
    bx = []
    for i, t in enumerate(bes):
        bx.append(_box(ax, 6 + i * 13, 59.5, 12, 9, t, "white", GREEN, fs=7.5))

    # AI layer
    _box(ax, 6, 28, 40, 24, "", ORANGE_L, ORANGE)
    ax.text(26, 50.5, "AI Layer", ha="center", fontsize=10, fontweight="bold", color=ORANGE)
    ai1 = _box(ax, 9, 40, 16, 8, "RAG System\n(Vector Search)", "white", ORANGE, fs=8)
    ai2 = _box(ax, 28, 40, 15, 8, "Feedback /\nTriage Handler", "white", ORANGE, fs=8)
    ai3 = _box(ax, 9, 30, 16, 7, "AI Model\n(Groq Llama 3.3)", "white", ORANGE, fs=8)

    # DB layer
    _box(ax, 52, 28, 44, 18, "", "#fdf3df", "#caا9".replace("ا", "0")) if False else _box(ax, 52, 28, 44, 18, "", "#fdf3df", "#caa000")
    ax.text(74, 44.5, "Database Layer", ha="center", fontsize=10, fontweight="bold", color="#9a7d00")
    db1 = _box(ax, 55, 33, 12, 8, "SQL/SQLite\nDatabase", "white", "#caa000", fs=8)
    db2 = _box(ax, 69, 33, 12, 8, "Firebase\nAuth", "white", "#caa000", fs=8)
    db3 = _box(ax, 83, 33, 11, 8, "Firebase\nStorage", "white", "#caa000", fs=8)

    # arrows
    _arrow(ax, (40, 87.5), (35, 68.5), GREY, rad=-0.1)   # admin -> backend
    _arrow(ax, (60, 87.5), (70, 68.5), GREY, rad=0.1)    # user -> backend
    _arrow(ax, (12, 59.5), (15, 48), ORANGE)             # chatbot -> RAG
    _arrow(ax, (17, 40), (15, 37), ORANGE)               # RAG -> model
    _arrow(ax, (45, 59.5), (61, 41), GREY, rad=0.15)     # med api -> db
    _arrow(ax, (58, 59.5), (75, 41), GREY, rad=0.1)      # auth -> firebase auth
    _arrow(ax, (84, 59.5), (88, 41), GREY, rad=0.1)      # prescription -> storage

    ax.set_title("Figure: MediAI High-Level Component Diagram", fontsize=11, fontweight="bold", pad=8)
    _save(fig, "fig_component.png")


# ─────────────────────────────────────────────────────────────────────────────
# 3. Use-case diagram
# ─────────────────────────────────────────────────────────────────────────────
def use_case_diagram():
    fig, ax = plt.subplots(figsize=(11, 9.5))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    def actor(x, y, label):
        ax.add_patch(Circle((x, y + 4), 1.4, fill=False, lw=1.5))
        ax.plot([x, x], [y, y + 2.6], "k-", lw=1.5)
        ax.plot([x - 2, x + 2], [y + 1.6, y + 1.6], "k-", lw=1.5)
        ax.plot([x, x - 1.8], [y, y - 2.4], "k-", lw=1.5)
        ax.plot([x, x + 1.8], [y, y - 2.4], "k-", lw=1.5)
        ax.text(x, y - 4, label, ha="center", fontsize=9, fontweight="bold")

    actor(6, 55, "Customer")
    actor(94, 55, "Admin")
    actor(50, 8, "System")

    # boundary
    _box(ax, 18, 16, 64, 78, "", "#fbfdff", BLUE)
    ax.text(50, 92, "MediAI Platform", ha="center", fontsize=10, fontweight="bold", color=BLUE)

    cust_uc = ["Register / Login", "Browse & Search Medicines", "View Product & Reviews",
               "Add to Cart / Wishlist", "Checkout & Apply Coupon", "Track Orders",
               "Add Medicine (Manual/OCR)", "Set Reminders & Alarms",
               "Manage Medicine Stock", "Consult AI Pharmacist",
               "Request Prescription Medicine", "Manage Profile"]
    admin_uc = ["Admin Login", "View Dashboard", "Manage Catalog", "Manage Products",
                "Process Orders", "Manage Customers", "Manage Banners",
                "Manage Coupons & Campaigns", "Review Prescriptions", "Manage Admins"]
    sys_uc = ["Sync Data (SQLite↔Cloud)", "Schedule Notifications",
              "Check Stock Levels", "Auto-Refill Stock", "Push Coupon Offers"]

    # customer ellipses (left col)
    y = 88
    for t in cust_uc:
        e = Ellipse((36, y), 26, 4.2, fill=True, fc=BLUE_L, ec=BLUE, lw=1.1, zorder=2)
        ax.add_patch(e)
        ax.text(36, y, t, ha="center", va="center", fontsize=7.4, zorder=3)
        _arrow(ax, (8, 55), (23, y), BLUE, lw=0.8, rad=0.02)
        y -= 6.0
    # admin ellipses (right col)
    y = 86
    for t in admin_uc:
        e = Ellipse((64, y), 26, 4.2, fill=True, fc=GREEN_L, ec=GREEN, lw=1.1, zorder=2)
        ax.add_patch(e)
        ax.text(64, y, t, ha="center", va="center", fontsize=7.4, zorder=3)
        _arrow(ax, (92, 55), (77, y), GREEN, lw=0.8, rad=-0.02)
        y -= 6.4
    # system ellipses (bottom centre)
    x = 30
    for t in sys_uc:
        e = Ellipse((x, 21), 13.5, 4.0, fill=True, fc=ORANGE_L, ec=ORANGE, lw=1.0, zorder=2)
        ax.add_patch(e)
        ax.text(x, 21, t, ha="center", va="center", fontsize=6.6, zorder=3)
        _arrow(ax, (50, 11), (x, 19), ORANGE, lw=0.8, rad=0.0)
        x += 14

    ax.set_title("Figure: MediAI Use-Case Diagram", fontsize=11, fontweight="bold", pad=8)
    _save(fig, "fig_usecase.png")


# ─────────────────────────────────────────────────────────────────────────────
# 4. ERD
# ─────────────────────────────────────────────────────────────────────────────
def erd_diagram():
    fig, ax = plt.subplots(figsize=(11.5, 9.5))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    def ent(x, y, w, title, rows, fc, ec):
        h = 4 + len(rows) * 2.7
        _box(ax, x, y - h, w, h, "", "white", ec)
        ax.add_patch(FancyBboxPatch((x, y - 3.4), w, 3.4,
                     boxstyle="round,pad=0.01,rounding_size=0.05", fc=fc, ec=ec, lw=1.1))
        ax.text(x + w / 2, y - 1.7, title, ha="center", va="center", fontsize=8.2, fontweight="bold")
        for i, r in enumerate(rows):
            ax.text(x + 1, y - 3.4 - 2.7 * (i + 1) + 1.0, r, ha="left", va="center", fontsize=6.6)
        return (x, y, w, h)

    ent(2, 98, 22, "Users (Firestore)",
        ["PK id (uid)", "FirstName / LastName", "Email / Phone", "role / points", "addresses[]", "CreatedAt"], BLUE_L, BLUE)
    ent(2, 70, 22, "Cart (sub)", ["PK cartItemId", "FK uid", "FK productId", "quantity / price"], BLUE_L, BLUE)
    ent(2, 54, 22, "Wishlist (sub)", ["PK wishlistId", "FK uid", "FK productId"], BLUE_L, BLUE)
    ent(2, 42, 22, "Notifications (sub)", ["PK notifId", "title / message", "type / isRead"], BLUE_L, BLUE)

    ent(28, 98, 24, "medicines (sub / SQLite)",
        ["PK medId", "FK uid", "medicine_name", "disease_name", "frequency / duration", "chronic", "total_no_of_doses", "available_stock", "alert_before_days", "synced"], GREEN_L, GREEN)
    ent(28, 56, 24, "alarms (sub / SQLite)",
        ["PK alarmId", "FK medId", "specific_dose", "time_hour / minute", "isActive", "synced"], GREEN_L, GREEN)
    ent(28, 34, 24, "pending_changes (SQLite)",
        ["PK id", "operation_type", "entity_type / id", "entity_data", "synced"], GREEN_L, GREEN)

    ent(57, 98, 20, "Categories", ["PK id", "Name / Image", "IsFeatured", "IsActive"], ORANGE_L, ORANGE)
    ent(57, 80, 20, "Subcategories", ["PK id", "FK CategoryId", "Name / Image", "IsFeatured"], ORANGE_L, ORANGE)
    ent(57, 62, 20, "Brands", ["PK id", "Name", "CategoryIds[]", "ProductCount"], ORANGE_L, ORANGE)
    ent(79, 98, 19, "Products", ["PK id", "Name / Formula", "Price / SalePrice", "Stock", "FK Category/Brand", "IsFeatured/Recommended"], ORANGE_L, ORANGE)
    ent(79, 70, 19, "Reviews (sub)", ["PK id", "FK productId", "FK userId", "rating / comment"], ORANGE_L, ORANGE)
    ent(57, 44, 20, "Orders", ["PK id", "FK customerId", "items[]", "orderStatus", "paymentStatus", "totalAmount"], "#eef0ff", PURPLE)
    ent(79, 44, 19, "Coupons / Banners", ["PK id", "Code / image", "DiscountValue", "Type / dates", "UsageLimit"], "#eef0ff", PURPLE)
    ent(57, 22, 20, "Admins", ["PK id (uid)", "Name / Email", "role", "IsActive"], "#eef0ff", PURPLE)

    # relationships
    _arrow(ax, (13, 92), (13, 70), BLUE, style="-|>", rad=0.0)
    _arrow(ax, (13, 66), (13, 54), BLUE)
    _arrow(ax, (13, 50), (13, 42), BLUE)
    _arrow(ax, (24, 88), (28, 80), GREEN, rad=0.1)
    _arrow(ax, (40, 70), (40, 56), GREEN)
    _arrow(ax, (52, 92), (57, 88), ORANGE, rad=0.1)
    _arrow(ax, (67, 80), (67, 86), ORANGE, style="<|-")
    _arrow(ax, (77, 88), (79, 86), ORANGE)
    _arrow(ax, (77, 62), (79, 80), ORANGE, rad=0.2)
    _arrow(ax, (88, 80), (88, 70), ORANGE)
    _arrow(ax, (24, 60), (28, 64), GREEN, style="<|-|>", rad=0.0)  # sqlite<->cloud sync

    ax.set_title("Figure: MediAI Entity-Relationship Diagram (Firestore + SQLite)", fontsize=11, fontweight="bold", pad=8)
    _save(fig, "fig_erd.png")


# ─────────────────────────────────────────────────────────────────────────────
# 5. Flowchart
# ─────────────────────────────────────────────────────────────────────────────
def flowchart():
    fig, ax = plt.subplots(figsize=(8.5, 11))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    def term(x, y, w, h, t, fc):
        ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.9",
                     fc=fc, ec=GREY, lw=1.2))
        ax.text(x + w / 2, y + h / 2, t, ha="center", va="center", fontsize=8)

    def proc(x, y, w, h, t, fc):
        _box(ax, x, y, w, h, t, fc, GREY, fs=8)

    def dec(x, y, w, h, t):
        ax.add_patch(plt.Polygon([(x + w / 2, y + h), (x + w, y + h / 2), (x + w / 2, y), (x, y + h / 2)],
                     fc="#fff3cd", ec=GREY, lw=1.2))
        ax.text(x + w / 2, y + h / 2, t, ha="center", va="center", fontsize=7.5)

    term(35, 93, 30, 5, "Start", "#dfeffd")
    proc(30, 84, 40, 6, "User registers / logs in\n(Firebase Auth)", BLUE_L)
    proc(30, 75, 40, 6, "Add medicine: manual entry\nor OCR prescription scan", GREEN_L)
    dec(33, 64, 34, 9, "OCR used?")
    proc(72, 65.5, 26, 6, "Gemini Vision\nextracts fields", ORANGE_L)
    proc(30, 54, 40, 6, "Save to SQLite + schedule\nlocal alarms", GREEN_L)
    proc(30, 45, 40, 6, "Queue change → sync to\nFirestore when online", BLUE_L)
    dec(33, 34, 34, 9, "Alarm time\nreached?")
    proc(30, 24, 40, 6, "Full-screen alarm:\nTake / Snooze / Dismiss", PURPLE_L)
    proc(30, 15, 40, 6, "Decrement stock; check\nlow-stock threshold", GREEN_L)
    dec(33, 4.5, 34, 8.5, "Stock low?")
    proc(72, 5.5, 26, 6, "Notify user;\nsuggest re-order", RED_L)
    term(2, 6, 24, 5, "Continue", "#dfeffd")

    _arrow(ax, (50, 93), (50, 90))
    _arrow(ax, (50, 84), (50, 81))
    _arrow(ax, (50, 75), (50, 73))
    _arrow(ax, (67, 68.5), (72, 68.5)); ax.text(69, 70, "Yes", fontsize=7)
    _arrow(ax, (85, 65.5), (85, 60)); _arrow(ax, (85, 60), (50, 60)); _arrow(ax, (50, 60), (50, 60.0001))
    _arrow(ax, (50, 64), (50, 60)); ax.text(52, 62, "No", fontsize=7)
    _arrow(ax, (50, 54), (50, 51))
    _arrow(ax, (50, 45), (50, 43))
    _arrow(ax, (50, 34), (50, 30)); ax.text(52, 32, "Yes", fontsize=7)
    _arrow(ax, (50, 24), (50, 21))
    _arrow(ax, (50, 15), (50, 13))
    _arrow(ax, (67, 8.5), (72, 8.5)); ax.text(69, 10, "Yes", fontsize=7)
    _arrow(ax, (33, 8.5), (26, 8.5)); ax.text(29, 10, "No", fontsize=7)

    ax.set_title("Figure: MediAI Reminder & Stock Workflow Flowchart", fontsize=11, fontweight="bold", pad=8)
    _save(fig, "fig_flowchart.png")


# ─────────────────────────────────────────────────────────────────────────────
# 6. Sequence diagram (chatbot RAG)
# ─────────────────────────────────────────────────────────────────────────────
def sequence_diagram():
    fig, ax = plt.subplots(figsize=(11, 8.5))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    actors = ["User", "Flutter\nChatService", "FastAPI\n/chat/rag", "Intent Router\n+ Triage", "Embedder +\nChromaDB", "Groq LLM\n(Llama 3.3)"]
    xs = [8, 25, 43, 60, 77, 93]
    for x, a in zip(xs, actors):
        _box(ax, x - 7, 92, 14, 6, a, BLUE_L, BLUE, fs=7.5)
        ax.plot([x, x], [10, 92], color=GREY, lw=0.8, ls="--", zorder=0)

    def msg(i, j, y, t, ret=False):
        style = "-|>" if not ret else "-|>"
        ls = "-" if not ret else (0, (4, 3))
        _arrow(ax, (xs[i], y), (xs[j], y), GREY if not ret else BLUE, style=style, ls=ls, lw=1.1)
        midx = (xs[i] + xs[j]) / 2
        ax.text(midx, y + 1.0, t, ha="center", fontsize=6.8, color="black")

    msg(0, 1, 86, "type question")
    msg(1, 2, 82, "POST {message, session_id}")
    msg(2, 3, 78, "classify intent / emergency")
    msg(3, 2, 74, "intent + route", ret=True)
    msg(2, 4, 68, "embed query → cosine search")
    msg(4, 2, 64, "top-K grounded chunks", ret=True)
    ax.text(50, 58.5, "[ alt: on-demand ingest if drug unknown — fetch DailyMed/OpenFDA, embed, store ]",
            ha="center", fontsize=6.6, style="italic", color=PURPLE)
    msg(2, 5, 53, "context + prompt")
    msg(5, 2, 49, "grounded answer", ret=True)
    msg(2, 1, 44, "{reply, sources, rag_used}", ret=True)
    msg(1, 0, 40, "display answer + citations", ret=True)
    ax.text(50, 33, "[ alt: rag_used == false → Flutter falls back to /chat general endpoint ]",
            ha="center", fontsize=6.6, style="italic", color=RED)

    ax.set_title("Figure: AI Chatbot (RAG) Sequence Diagram", fontsize=11, fontweight="bold", pad=8)
    _save(fig, "fig_sequence.png")


# ─────────────────────────────────────────────────────────────────────────────
# 7. Activity diagram (order / checkout)
# ─────────────────────────────────────────────────────────────────────────────
def activity_diagram():
    fig, ax = plt.subplots(figsize=(8.5, 11))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    ax.add_patch(Circle((50, 96), 1.6, color="black"))
    steps = [
        ("Browse store / search products", BLUE_L),
        ("View product details & reviews", BLUE_L),
        ("Add item to cart", GREEN_L),
        ("Open cart → adjust quantity", GREEN_L),
        ("Proceed to checkout", GREEN_L),
        ("Select shipping address", PURPLE_L),
        ("Apply coupon (server-validated)", PURPLE_L),
        ("Choose payment method", PURPLE_L),
        ("Place order → write to Firestore", ORANGE_L),
        ("Clear cart; show success screen", ORANGE_L),
        ("Admin processes & updates status", "#e7e7e7"),
        ("On delivery → auto-refill stock", GREEN_L),
    ]
    y = 90
    prev = (50, 94.4)
    for t, c in steps:
        _box(ax, 22, y, 56, 5.2, t, c, GREY, fs=8)
        _arrow(ax, prev, (50, y + 5.2))
        prev = (50, y)
        y -= 7.2
    ax.add_patch(Circle((50, y + 4.0), 1.9, fill=False, lw=1.6))
    ax.add_patch(Circle((50, y + 4.0), 1.0, color="black"))
    _arrow(ax, prev, (50, y + 5.9))

    ax.set_title("Figure: E-Commerce Order Activity Diagram", fontsize=11, fontweight="bold", pad=8)
    _save(fig, "fig_activity.png")


# ─────────────────────────────────────────────────────────────────────────────
# 8. RAG pipeline diagram
# ─────────────────────────────────────────────────────────────────────────────
def rag_pipeline():
    fig, ax = plt.subplots(figsize=(8.5, 11))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")
    steps = [
        ("User question", BLUE_L),
        ("Emergency / cancel pre-check", RED_L),
        ("Intent classification + routing", PURPLE_L),
        ("Direct index lookup?\n(brand/generic/ingredient)", "#fff3cd"),
        ("Embed query — BAAI/bge-small (384-d)", GREEN_L),
        ("ChromaDB cosine search (top-K)", GREEN_L),
        ("Score >= 0.50 filter", "#fff3cd"),
        ("On-demand ingest if no hit\n(DailyMed + OpenFDA + RxNorm)", ORANGE_L),
        ("Build grounded context block", GREEN_L),
        ("Groq Llama 3.3 70B generation", PURPLE_L),
        ("Append citations + confidence", BLUE_L),
    ]
    y = 91
    prev = None
    for t, c in steps:
        _box(ax, 16, y, 68, 6, t, c, GREY, fs=8)
        if prev:
            _arrow(ax, prev, (50, y + 6))
        prev = (50, y)
        y -= 8.2
    ax.text(88, 70, "answer here →\nno LLM call", fontsize=6.6, color="#9a7d00", rotation=0)
    _arrow(ax, (84, 73), (92, 73), "#caa000")
    ax.set_title("Figure: Retrieval-Augmented Generation (RAG) Pipeline", fontsize=11, fontweight="bold", pad=8)
    _save(fig, "fig_rag.png")


# ─────────────────────────────────────────────────────────────────────────────
# 9. Toolchain / technology workflow
# ─────────────────────────────────────────────────────────────────────────────
def toolchain():
    fig, ax = plt.subplots(figsize=(11, 6.5))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")

    _box(ax, 3, 60, 22, 28, "Frontend\n\nFlutter (Dart)\nGetX\nMaterial 3\nGetStorage", BLUE_L, BLUE, fs=8)
    _box(ax, 30, 60, 22, 28, "AI Backend\n\nFastAPI (Python)\nGroq Llama 3.3\nChromaDB\nbge-small embeddings", PURPLE_L, PURPLE, fs=8)
    _box(ax, 57, 60, 18, 28, "OCR\n\nGemini 2.5\nFlash Vision", ORANGE_L, ORANGE, fs=8)
    _box(ax, 80, 60, 17, 28, "External APIs\n\nDailyMed\nOpenFDA\nRxNorm", "#eef0ff", "#caa000", fs=8)

    _box(ax, 3, 18, 22, 30, "Firebase\n\nAuth (Email/\nGoogle/Facebook)\nFirestore\nStorage\nCloud Messaging", "#eaf3fb", BLUE, fs=8)
    _box(ax, 30, 18, 22, 30, "Local Storage\n\nSQLite (sqflite)\nOffline queue\nWorkManager\nLocal notifications", GREEN_L, GREEN, fs=8)
    _box(ax, 57, 18, 18, 30, "Admin Panel\n\nFlutter Web\nGetX\nExcel export", GREEN_L, GREEN, fs=8)
    _box(ax, 80, 18, 17, 30, "DevOps\n\nGit / VS Code\npub / pip\nUvicorn", GREY_L, GREY, fs=8)

    for x in (14, 41, 66, 88):
        _arrow(ax, (x, 60), (x, 48), GREY, rad=0.0)

    ax.set_title("Figure: Toolchain and Technology Workflow", fontsize=11, fontweight="bold", pad=8)
    _save(fig, "fig_toolchain.png")


if __name__ == "__main__":
    system_architecture()
    component_diagram()
    use_case_diagram()
    erd_diagram()
    flowchart()
    sequence_diagram()
    activity_diagram()
    rag_pipeline()
    toolchain()
    print("All diagrams generated.")
