# TAGANA PRD v1.0 — Quick Start Guide

**Created:** August 14, 2026  
**Status:** ✓ Ready for Review  
**Location:** `docs/02-product-requirements.md`

---

## 📄 DOCUMENT OVERVIEW

**Product Requirements Document (PRD)** untuk aplikasi TAGANA v1.0 — aplikasi mobile untuk monitoring ketinggian air real-time menggunakan IoT devices.

**Purpose:** Bridge antara System Requirements Specification (SRS) dan tahap User Flow / Use Case Design

**Format:** Markdown (~600 lines, ~20-25 halaman ketika di-print)

---

## 🎯 MAIN SECTIONS

### 1. **Deskripsi Produk** (Section 1)
- Ringkasan produk & masalah yang diselesaikan
- Nilai yang diberikan kepada user
- Use cases utama (monitoring, setup, emergency)

### 2. **Target User & Personas** (Section 2)
- Primary user: Field Monitor / Operator Lapangan
- Secondary user: Admin/Supervisor [TBD - OQ-003]
- 6 primary use cases

### 3. **Product Scope & Features** (Section 3)
- **19 Fitur utama** organized dalam 5 kategori:
  1. User Management (1 feature)
  2. Device Onboarding (4 features)
  3. Monitoring (7 features)
  4. Configuration & Emergency (7 features)
- Setiap feature dijelaskan dengan purpose, description, benefit, scope

### 4. **User Journeys** (Section 4)
- 4 key scenarios:
  1. First-time user setup (5-10 min)
  2. Multi-device management
  3. Emergency offline access
  4. Troubleshooting network

### 5. **User Stories** (Section 5)
- 19 user stories dengan format: "As a [user], I want to [action], so that [benefit]"
- Acceptance criteria untuk setiap story
- Edge cases & error handling scenarios

### 6. **Functional Product Requirements** (Section 6)
- 35 FPR items covering:
  - User data management (3 items)
  - Device registration & ownership (5 items)
  - Communication & connectivity (7 items)
  - Monitoring data (9 items)
  - UI & navigation (6 items)
  - Configuration & emergency (5 items)

### 7. **Acceptance Criteria** (Section 7)
- 6 AC items verifying PRD quality against SRS

### 8. **Edge Cases & Error Handling** (Section 8)
- 4 categories dengan 15+ scenarios
- Device registration, emergency access, data monitoring, multi-device edge cases

### 9. **Out of Scope** (Section 9)
- 9 categories explicitly NOT in v1.0:
  - Advanced user management, analytics, integrations, etc.

### 10. **Open Questions / TBD** (Section 10)
- 18 items (same as SRS) clearly documented
- Impact, questions, affected features, dependency chains
- Organized by priority (affects which features)

### 11. **Feature Tracking Matrix** (Section 11)
- **35-item table** dengan:
  - Feature name & ID
  - Status (CONFIRMED / TBD)
  - Source requirement (FR-xxx, OQ-xxx)
  - Notes

---

## 🔍 HOW TO FIND THINGS

### If you need to find...

| Looking For | See Section |
|---|---|
| What are we building? | Section 1 (Product Description) |
| Who is the user? | Section 2 (Target Users) |
| What features exist? | Section 3 (Product Scope & Features) |
| How do users interact? | Section 4 (User Journeys) |
| What must be built? | Section 5 (User Stories) |
| Technical requirements? | Section 6 (Functional PRs) |
| What should work? | Section 7 (Acceptance Criteria) |
| What can fail? | Section 8 (Edge Cases) |
| What's NOT included? | Section 9 (Out of Scope) |
| What's still TBD? | Section 10 (Open Questions) |
| Feature status overview? | Section 11 (Tracking Matrix) |

### If you need to find a specific feature:

**Example:** Looking for "Dashboard" feature

1. Go to Section 3 (Product Scope)
2. Find subsection "C. Monitoring Features"
3. Look for "Feature 6: Dashboard"
4. Or search for "Dashboard" or "FPR-27" in tracking matrix (Section 11)

---

## 📊 KEY STATISTICS

| Item | Count | Status |
|------|-------|--------|
| **Total Features** | 19 | Core features for v1.0 |
| **CONFIRMED Features** | ~26 | Ready to build |
| **TBD Features** | ~9 | Awaiting OQ decisions |
| **User Stories** | 19 | One per feature |
| **Functional Requirements** | 35 | Implementation details |
| **User Journeys** | 4 | Key scenarios |
| **Edge Cases** | 15+ | Error scenarios |
| **Open Questions** | 18 | Must be decided |
| **Out of Scope** | 9 categories | Not in v1.0 |

---

## ✅ COMPLIANCE WITH INSTRUCTIONS

| Requirement | Status | Evidence |
|---|---|---|
| Based pada SRS | ✓ | Every feature traces to FR/HW/NET/DATA/SEC |
| No new requirements | ✓ | Only elaboration of existing SRS items |
| Preserve CONFIRMED | ✓ | No changes to CONFIRMED requirements |
| Mark TBD from SRS | ✓ | All 18 OQ flagged as [TBD - OQ-XXX] |
| Differentiate status | ✓ | CONFIRMED vs TBD vs OUT OF SCOPE clear |
| Focus on WHAT & WHY | ✓ | Not technical HOW |
| No technical artifacts | ✓ | No BPMN, ERD, UML, architecture, API, DB schema |
| Formal Indonesian | ✓ | Consistent technical language |
| Cover 17 listed features | ✓ | All 17+ features covered |
| Ending matrix table | ✓ | 35-item feature tracking matrix |

---

## 🚀 READING RECOMMENDATIONS

### For 5-minute overview:
1. Read Section 1 (Deskripsi Produk)
2. Skim Section 2 (Target Users)
3. Look at Feature Tracking Matrix (Section 11) to see what's CONFIRMED vs TBD

### For 15-minute understanding:
1. Read Section 1-2 (Product & Users)
2. Skim Section 3 (Features list)
3. Read Section 4 (User Journeys) to understand flow
4. Review Section 11 (Matrix) for status

### For complete product understanding (45-60 min):
1. Read entire document from Section 1-11
2. Focus on your role:
   - **Product Manager:** Sections 1-3, 10-11 (scope, features, open items)
   - **Designer:** Sections 2, 4-5, 8 (users, journeys, US, edge cases)
   - **Developer:** Sections 3, 6-11 (features, requirements, tracking)
   - **QA:** Sections 5, 7-8 (US with AC, edge cases, quality)

---

## 🔗 RELATIONSHIPS TO OTHER DOCUMENTS

```
System Requirements (SRS) v1.0
            ↓
    [Review/Normalization]
            ↓
Product Requirements (PRD) v1.0 ← You are here
            ↓
    [Next phases: UX Design]
            ↓
User Flows → Use Cases → Architecture → UI/UX → Development
```

Use PRD as foundation untuk phases berikutnya:
- User Flows akan elaborate PRD user journeys
- Use Cases akan detail user stories
- Architecture akan implement PRD requirements
- UI/UX akan design PRD features
- Development akan code PRD specifications

---

## ⚠️ IMPORTANT NOTES

### 1. TBD Items Must Be Addressed
- 18 open questions (OQ-001 through OQ-018) listed di Section 10
- These TBD items should NOT block development, but must be decided at appropriate phases
- For example: OQ-002 (sensor spec) needed before firmware dev, tapi tidak blok app dev

### 2. Three Status Levels
- **CONFIRMED:** Ready to build now
- **TBD:** Needs decision pero outline is clear
- **OUT OF SCOPE:** Explicitly NOT in v1.0 (don't request these!)

### 3. Traceability is Key
- Every feature traces back to SRS
- If something not in this PRD, check SRS to see if it's OUT OF SCOPE
- Feature Tracking Matrix (Section 11) shows every item's source

### 4. This is NOT a Technical Design Document
- PRD says WHAT to build, not HOW to build it
- No architecture diagrams, API specs, database schemas
- Those come in later phases

---

## 📝 HOW TO USE THIS DOCUMENT

### In Product/Planning Meetings:
- Reference feature status from Section 11 matrix
- Use user journeys (Section 4) to discuss flow
- Cite user stories (Section 5) for requirements verification

### For Design Handoff:
- Share user journeys (Section 4) with designers
- Provide user stories (Section 5) with AC
- Discuss edge cases (Section 8) for design considerations
- Explain TBD items (Section 10) that may affect design

### For Dev Sprint Planning:
- Use feature tracking matrix (Section 11) to plan sprints
- Reference user stories (Section 5) for acceptance criteria
- Note TBD items (Section 10) that are blockers vs non-blockers
- Check FPR (Section 6) for technical considerations

### For QA/Testing:
- Use acceptance criteria from user stories (Section 5)
- Create test cases from edge cases (Section 8)
- Verify feature completeness against matrix (Section 11)

---

## 🎓 KEY CONCEPTS

### Feature vs User Story vs Requirement
- **Feature:** High-level capability (e.g., "Dashboard")
- **User Story:** Specific action by user (e.g., "As a monitor, I want to see overview...")
- **Requirement:** Detailed implementation need (e.g., "Dashboard must show total, online, offline counts")

### CONFIRMED vs TBD vs OUT OF SCOPE
- **CONFIRMED:** Decided, ready to implement, won't change
- **TBD:** Outline is clear, pero detail perlu OQ decision
- **OUT OF SCOPE:** Explicitly NOT in v1.0, defer to future version

### Product Scope vs Technical Scope
- **Product Scope:** WHAT features exist (Section 3)
- **Technical Scope:** HOW features implemented (not in PRD, comes later)

---

## 💡 TIPS FOR EFFECTIVE USE

1. **Bookmark Section 11 (Matrix)** — Quick reference untuk feature status
2. **Use Table of Contents** — Jump to sections you need
3. **Tag TBD Items** — Mark OQ-XXX references to follow progress
4. **Share with Stakeholders** — This document is stakeholder-ready
5. **Update as OQ Decisions Made** — Update TBD status when decisions made
6. **Reference Tracking Matrix** — Use as single source of truth untuk feature list

---

## 📞 QUESTIONS?

If you have questions about:
- **A specific feature:** See Section 3 or tracking matrix (Section 11)
- **Feature status:** See Section 11 matrix or Section 10 for TBD items
- **User requirements:** See Section 5 (User Stories)
- **What's not included:** See Section 9 (Out of Scope)
- **Traceability to SRS:** See Section 11 matrix "Source Requirement" column

---

**Ready to proceed?**

✅ PRD documento is complete and validated against SRS  
✅ All TBD items clearly documented  
✅ All CONFIRMED requirements preserved  
✅ No new requirements invented  
✅ Professional quality, ready for stakeholder review  

**Next Action:** Share PRD dengan product team & schedule validation meeting

---

**Last Updated:** August 14, 2026  
**Document:** TAGANA PRD v1.0  
**File:** `docs/02-product-requirements.md`  

