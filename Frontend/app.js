// ============================================================
// LabTrack Pro – Doctor Lab Test Reports System
// Frontend Application Logic
// ============================================================

const views = {
  dashboard: { title: 'Dashboard',     breadcrumb: 'Dashboard' },
  patients:  { title: 'Patients',      breadcrumb: 'Patients' },
  reports:   { title: 'Lab Reports',   breadcrumb: 'Diagnostics / Lab Reports' },
  orders:    { title: 'Test Orders',   breadcrumb: 'Diagnostics / Test Orders' },
  critical:  { title: 'Critical Alerts', breadcrumb: 'Diagnostics / Critical Alerts' },
  schema:    { title: 'DB Schema',     breadcrumb: 'System / DB Schema' },
  queries:   { title: 'SQL Queries',   breadcrumb: 'System / SQL Queries' },
  audit:     { title: 'Audit Trail',   breadcrumb: 'System / Audit Trail' },
};

function showView(viewName) {
  // Hide all views
  document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));

  // Show target view
  const viewEl = document.getElementById('view-' + viewName);
  if (viewEl) viewEl.classList.add('active');

  // Update nav
  const navEl = document.querySelector(`.nav-item[data-view="${viewName}"]`);
  if (navEl) navEl.classList.add('active');

  // Update header
  const meta = views[viewName];
  if (meta) {
    document.getElementById('pageTitle').textContent = meta.title;
    document.getElementById('breadcrumbCurrent').textContent = meta.breadcrumb;
  }
}

// Nav click handlers
document.querySelectorAll('.nav-item').forEach(item => {
  item.addEventListener('click', (e) => {
    e.preventDefault();
    const view = item.dataset.view;
    if (view) showView(view);
  });
});

// Report filter functionality
const filterCategory = document.getElementById('filterCategory');
const filterStatus   = document.getElementById('filterStatus');

function applyFilters() {
  const cat    = filterCategory ? filterCategory.value : '';
  const status = filterStatus   ? filterStatus.value   : '';

  document.querySelectorAll('#reportsTable tbody tr').forEach(row => {
    const rowCat  = row.dataset.cat  || '';
    const rowFlag = row.dataset.flag || '';

    let show = true;
    if (cat    && rowCat  !== cat)                                show = false;
    if (status === 'Normal'   && rowFlag !== 'normal')            show = false;
    if (status === 'Abnormal' && !['abnormal'].includes(rowFlag)) show = false;
    if (status === 'Critical' && rowFlag !== 'critical')          show = false;

    row.style.display = show ? '' : 'none';
  });
}

if (filterCategory) filterCategory.addEventListener('change', applyFilters);
if (filterStatus)   filterStatus.addEventListener('change', applyFilters);

// Global search (simple client-side highlight)
const globalSearch = document.getElementById('globalSearch');
if (globalSearch) {
  globalSearch.addEventListener('input', function () {
    const q = this.value.toLowerCase().trim();
    if (!q) {
      document.querySelectorAll('td').forEach(td => td.style.background = '');
      return;
    }
    document.querySelectorAll('td').forEach(td => {
      if (td.textContent.toLowerCase().includes(q)) {
        td.style.background = 'rgba(240,165,0,0.12)';
      } else {
        td.style.background = '';
      }
    });
  });
}

// Animate bar chart on dashboard load
function animateBars() {
  document.querySelectorAll('.bar-fill').forEach(bar => {
    const targetWidth = bar.style.width;
    bar.style.width = '0%';
    requestAnimationFrame(() => {
      setTimeout(() => { bar.style.width = targetWidth; }, 50);
    });
  });
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  showView('dashboard');
  animateBars();
});
