// Global variables
let allProducts = [];
let trendingProducts = [];

// DOM elements
const productsGrid = document.getElementById('productsGrid');
const trendingGrid = document.getElementById('trendingGrid');
const searchInput = document.getElementById('searchInput');
const sortSelect = document.getElementById('sortSelect');
const filterSelect = document.getElementById('filterSelect');
const refreshBtn = document.getElementById('refreshBtn');
const urlInput = document.getElementById('urlInput');
const addUrlsBtn = document.getElementById('addUrlsBtn');
const crawlingStatus = document.getElementById('crawlingStatus');

// Tab navigation
const navTabs = document.querySelectorAll('.nav-tab');
const tabContents = document.querySelectorAll('.tab-content');

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    initializeTabs();
    loadProducts();
    setupEventListeners();
});

// Tab functionality
function initializeTabs() {
    navTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const targetTab = tab.getAttribute('data-tab');
            switchTab(targetTab);
        });
    });
}

function switchTab(tabName) {
    // Update active tab
    navTabs.forEach(tab => {
        tab.classList.remove('active');
        if (tab.getAttribute('data-tab') === tabName) {
            tab.classList.add('active');
        }
    });

    // Update active content
    tabContents.forEach(content => {
        content.classList.remove('active');
        if (content.id === `${tabName}-tab`) {
            content.classList.add('active');
        }
    });

    // Load specific content
    if (tabName === 'trending') {
        loadTrendingProducts();
    }
}

// Event listeners
function setupEventListeners() {
    // Search functionality
    searchInput.addEventListener('input', handleSearch);
    
    // Sort functionality
    sortSelect.addEventListener('change', handleSort);
    
    // Filter functionality
    filterSelect.addEventListener('change', handleFilter);
    
    // Refresh button
    refreshBtn.addEventListener('click', loadProducts);
    
    // Recrawl all button
    const recrawlAllBtn = document.getElementById('recrawlAllBtn');
    if (recrawlAllBtn) {
        recrawlAllBtn.addEventListener('click', recrawlAllProducts);
    }
    
    // URL submission
    addUrlsBtn.addEventListener('click', handleUrlSubmission);
    
    // Settings event listeners
    const saveCrawlIntervalBtn = document.getElementById('saveCrawlInterval');
    const clearDatabaseBtn = document.getElementById('clearDatabase');
    
    if (saveCrawlIntervalBtn) {
        saveCrawlIntervalBtn.addEventListener('click', saveCrawlInterval);
    }
    
    if (clearDatabaseBtn) {
        clearDatabaseBtn.addEventListener('click', clearDatabase);
    }

    // Load crawl interval when settings tab is opened
    const settingsTab = document.querySelector('[data-tab="settings"]');
    if (settingsTab) {
        settingsTab.addEventListener('click', () => {
            setTimeout(loadCrawlInterval, 100); // Small delay to ensure tab is loaded
        });
    }
}
// Recrawl all existing products
async function recrawlAllProducts() {
    try {
        if (!allProducts || allProducts.length === 0) {
            showError('No products to recrawl');
            return;
        }
        const urls = allProducts.map(p => p.url).filter(Boolean);
        if (urls.length === 0) {
            showError('No valid URLs to recrawl');
            return;
        }
        showLoadingStatus(`Starting recrawl for ${urls.length} products...`);
        const response = await fetch('/api/crawl', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ urls })
        });
        if (!response.ok) {
            const data = await response.json().catch(() => ({}));
            throw new Error(data.error || 'Failed to start recrawl');
        }
        showSuccessStatus('Recrawl started');
        // Start real-time updates for all URLs
        startRealTimeUpdates(urls);
    } catch (err) {
        console.error('Recrawl all failed:', err);
        showErrorStatus('Recrawl all failed: ' + (err.message || 'Unknown error'));
    }
}

// Load products from API
async function loadProducts() {
    try {
        showLoading(productsGrid);
        
        const response = await fetch('/api/products');
        const data = await response.json();
        
        if (response.ok) {
            allProducts = data.products || [];
            trendingProducts = data.trending || [];
            
            renderProducts(allProducts);
            showSuccess('Products loaded successfully');
        } else {
            throw new Error(data.error || 'Failed to load products');
        }
    } catch (error) {
        console.error('Error loading products:', error);
        showError('Failed to load products');
        renderNoProducts();
    }
}

// Load trending products
function loadTrendingProducts() {
    if (trendingProducts.length > 0) {
        renderTrendingProducts(trendingProducts);
    } else {
        trendingGrid.innerHTML = `
            <div class="no-products-message">
                <i class="fas fa-fire"></i>
                <p>No trending products found</p>
            </div>
        `;
    }
}

// Render products grid
function renderProducts(products) {
    if (!products || products.length === 0) {
        renderNoProducts();
        return;
    }

    productsGrid.innerHTML = products.map(product => createProductCard(product)).join('');
}

// Render trending products
function renderTrendingProducts(products) {
    if (!products || products.length === 0) {
        trendingGrid.innerHTML = `
            <div class="no-products-message">
                <i class="fas fa-fire"></i>
                <p>No trending products found</p>
            </div>
        `;
        return;
    }

    trendingGrid.innerHTML = products.map(product => createProductCard(product, true)).join('');
}

// Create product card
function createProductCard(product, isTrending = false) {
    const price = product.price ? `$${product.price}` : 'N/A';
    const rank = product.rank ? `#${product.rank.toLocaleString()}` : 'N/A';
    const directImageUrl = product.image_url && product.image_url !== 'Not found' ? product.image_url : null;
    const proxyImageUrl = directImageUrl ? `/api/proxy-image?url=${encodeURIComponent(directImageUrl)}` : null;
    const lastUpdate = product.last_update || 'Unknown';
    const rankChangePercent = product.rank_change_percent;
    
    const trendingBadge = isTrending ? '<div class="trending-badge"><i class="fas fa-fire"></i> Trending</div>' : '';
    const rankChangeDisplay = rankChangePercent ? 
        `<span class="rank-change ${rankChangePercent > 0 ? 'rank-up' : 'rank-down'}">${rankChangePercent > 0 ? '+' : ''}${rankChangePercent}%</span>` : '';
    
    // Add rank trend indicator
    const rankTrend = product.rank_trend || 'new';
    const trendIcon = rankTrend === 'up' ? 'fa-arrow-up' : 
                     rankTrend === 'down' ? 'fa-arrow-down' : 
                     rankTrend === 'stable' ? 'fa-minus' : 'fa-star';
    const trendClass = rankTrend === 'up' ? 'trend-up' : 
                      rankTrend === 'down' ? 'trend-down' : 
                      rankTrend === 'stable' ? 'trend-stable' : 'trend-new';

    return `
        <div class="product-card" data-id="${product.id}">
            ${trendingBadge}
            <div class="last-update">Last update: ${lastUpdate}</div>
            
            <div class="product-image" onclick="openProductUrl('${product.url}')" style="cursor: pointer;">
                ${directImageUrl ? 
                    `<img src="${directImageUrl}" alt="${product.name}" onerror="if(!this.dataset.retry){this.dataset.retry='1'; this.src='${proxyImageUrl}';} else { this.style.display='none'; this.nextElementSibling.style.display='flex'; }">` : 
                    ''
                }
                <div class="no-image" style="${directImageUrl ? 'display: none;' : ''}">
                    <i class="fas fa-image"></i>
                </div>
            </div>
            
            <div class="product-info">
                <h3 class="product-title">
                    <a href="${product.url}" target="_blank">${product.name}</a>
                </h3>
                
                <div class="product-asin">
                    <span>ASIN: ${product.asin || 'N/A'}</span>
                    <div class="asin-actions">
                        <i class="fas fa-external-link-alt" title="Open link" onclick="openProductUrl('${product.url}')"></i>
                        <i class="fas fa-copy" title="Copy ASIN" onclick="copyToClipboard('${product.asin || 'N/A'}')"></i>
                        <i class="fas fa-search" title="Search" onclick="searchASIN('${product.asin || 'N/A'}')"></i>
                    </div>
                </div>
                
                <div class="product-brand">
                    <span>${product.brand || 'N/A'}</span>
                </div>
                
                <div class="product-ratings">
                    <div class="stars">
                        ${generateStars(product.stars)}
                    </div>
                    <span class="ratings-count">${product.ratings || 'N/A'} ratings</span>
                </div>
                
                <div class="product-meta">
                    <div class="product-rank">
                        Rank: ${rank}
                        <i class="fas ${trendIcon} ${trendClass}"></i>
                    </div>
                    <div class="product-date">Date: ${product.date || 'N/A'}</div>
                </div>
                
                <div class="product-actions">
                    <button class="crawl-btn" title="Re-crawl this product" onclick="crawlProduct('${product.url}', ${product.id})">
                        <i class="fas fa-play"></i>
                    </button>
                    <button class="delete-btn" onclick="deleteProduct(${product.id})">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
        </div>
    `;
}

// Crawl a single product by URL
async function crawlProduct(url, productId) {
    try {
        if (!url || url === 'Not found') {
            showError('No valid URL to crawl');
            return;
        }

        const card = document.querySelector(`.product-card[data-id="${productId}"]`);
        const button = card ? card.querySelector('.crawl-btn') : null;
        if (button) {
            button.disabled = true;
            button.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
        }

        showLoadingStatus('Starting crawling for selected product...');

        const response = await fetch('/api/crawl', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ urls: [url] })
        });

        const data = await response.json().catch(() => ({}));
        if (!response.ok) {
            throw new Error(data.error || 'Failed to start crawl');
        }

        showSuccessStatus('Crawling started');
        // Reuse existing real-time updates mechanism for a single URL
        startRealTimeUpdates([url]);
    } catch (err) {
        console.error('Crawl product failed:', err);
        showErrorStatus('Crawl failed: ' + (err.message || 'Unknown error'));
    } finally {
        const card = document.querySelector(`.product-card[data-id="${productId}"]`);
        const button = card ? card.querySelector('.crawl-btn') : null;
        if (button) {
            button.disabled = false;
            button.innerHTML = '<i class="fas fa-play"></i>';
        }
    }
}

// Render no products message
function renderNoProducts() {
    productsGrid.innerHTML = `
        <div class="no-products-message">
            <i class="fas fa-box-open"></i>
            <p>No products found</p>
            <p>Add some Amazon URLs in the URL Manager to get started!</p>
        </div>
    `;
}

// Search functionality
function handleSearch() {
    const searchTerm = searchInput.value.toLowerCase();
    const filteredProducts = allProducts.filter(product => 
        product.name.toLowerCase().includes(searchTerm) ||
        (product.asin && product.asin.toLowerCase().includes(searchTerm)) ||
        (product.brand && product.brand.toLowerCase().includes(searchTerm))
    );
    renderProducts(filteredProducts);
}

// Sort functionality
function handleSort() {
    const sortBy = sortSelect.value;
    const sortedProducts = [...allProducts].sort((a, b) => {
        switch (sortBy) {
            case 'rank':
                // Check if values are N/A
                const aIsNA = !a.rank || a.rank === 'N/A';
                const bIsNA = !b.rank || b.rank === 'N/A';
                
                // Put non-N/A values first
                if (aIsNA && !bIsNA) return 1;
                if (!aIsNA && bIsNA) return -1;
                if (aIsNA && bIsNA) return 0;
                
                // Sort by rank value
                return parseInt(a.rank) - parseInt(b.rank);
                
            case 'date':
                // Check if values are N/A
                const aDateIsNA = !a.date || a.date === 'N/A';
                const bDateIsNA = !b.date || b.date === 'N/A';
                
                // Put non-N/A values first
                if (aDateIsNA && !bDateIsNA) return 1;
                if (!aDateIsNA && bDateIsNA) return -1;
                if (aDateIsNA && bDateIsNA) return 0;
                
                // Sort by date value (newest first)
                const aDate = new Date(a.date);
                const bDate = new Date(b.date);
                return bDate - aDate;
                
            case 'name':
                return a.name.localeCompare(b.name);
                
            case 'ratings':
                // Check if values are N/A
                const aRatingsIsNA = !a.ratings || a.ratings === 'N/A';
                const bRatingsIsNA = !b.ratings || b.ratings === 'N/A';
                
                // Put non-N/A values first
                if (aRatingsIsNA && !bRatingsIsNA) return 1;
                if (!aRatingsIsNA && bRatingsIsNA) return -1;
                if (aRatingsIsNA && bRatingsIsNA) return 0;
                
                // Sort by ratings value (descending)
                return parseInt(b.ratings) - parseInt(a.ratings);
                
            default:
                return 0;
        }
    });
    renderProducts(sortedProducts);
}

// Filter functionality
function handleFilter() {
    const filterBy = filterSelect.value;
    let filteredProducts = allProducts;
    
    if (filterBy === 'trending') {
        filteredProducts = allProducts.filter(product => 
            product.rank_change_percent && product.rank_change_percent > 10
        );
    }
    
    renderProducts(filteredProducts);
}

// URL submission
async function handleUrlSubmission() {
    const urlsText = urlInput.value.trim();
    
    if (!urlsText) {
        showError('Please enter at least one URL');
        return;
    }
    
    const urls = urlsText.split('\n')
        .map(url => url.trim())
        .filter(url => url.length > 0)
        .filter(url => url.includes('amazon.com'));
    
    if (urls.length === 0) {
        showError('Please enter valid Amazon URLs');
        return;
    }
    
    try {
        showLoadingStatus('Starting crawling process...');
        
        // Add loading cards for each URL
        addLoadingCards(urls);
        
        const response = await fetch('/api/crawl', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ urls })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showSuccessStatus('Crawling started successfully!');
            // Clear textarea immediately after successful submission
            urlInput.value = '';
            
            // Start real-time updates
            startRealTimeUpdates(urls);
        } else {
            throw new Error(data.error || 'Crawling failed');
        }
    } catch (error) {
        console.error('Error starting crawling:', error);
        showErrorStatus('Failed to start crawling: ' + error.message);
    }
}

// Add loading cards for URLs
function addLoadingCards(urls) {
    const loadingCards = urls.map((url, index) => `
        <div class="product-card loading-card" data-url="${url}" data-index="${index}">
            <div class="product-image">
                <div class="no-image">
                    <i class="fas fa-spinner fa-spin"></i>
                </div>
            </div>
            <div class="product-info">
                <h3 class="product-title">Loading product...</h3>
                <div class="product-asin">
                    <span>ASIN: Loading...</span>
                    <div class="asin-actions">
                        <i class="fas fa-external-link-alt" style="opacity: 0.5; cursor: not-allowed;"></i>
                        <i class="fas fa-copy" style="opacity: 0.5; cursor: not-allowed;"></i>
                        <i class="fas fa-search" style="opacity: 0.5; cursor: not-allowed;"></i>
                    </div>
                </div>
                <div class="product-brand">
                    <span>Brand: Loading...</span>
                </div>
                <div class="product-ratings">
                    <div class="stars">
                        <i class="fas fa-star"></i>
                        <i class="fas fa-star"></i>
                        <i class="fas fa-star"></i>
                        <i class="fas fa-star"></i>
                        <i class="far fa-star"></i>
                    </div>
                    <span class="ratings-count">Loading... ratings</span>
                </div>
                <div class="product-meta">
                    <div class="product-rank">Rank: Loading...</div>
                    <div class="product-date">Date: Loading...</div>
                </div>
                <div class="product-actions">
                    <button class="delete-btn" disabled>
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </div>
            </div>
        </div>
    `).join('');
    
    // Add loading cards to the beginning of the grid
    productsGrid.insertAdjacentHTML('afterbegin', loadingCards);
}

// Start real-time updates
function startRealTimeUpdates(urls) {
    let processedUrls = new Set(); // Track processed URLs
    
    const updateInterval = setInterval(async () => {
        try {
            // Check crawl status for specific URLs
            const statusResponse = await fetch(`/api/crawl-status?urls=${encodeURIComponent(JSON.stringify(urls))}`);
            const statusData = await statusResponse.json();
            
            if (statusResponse.ok) {
                // Update loading cards with real data as soon as they're available
                urls.forEach((url, index) => {
                    const status = statusData[url];
                    if (status && status.crawled && !processedUrls.has(url)) {
                        // Get full product data
                        fetch('/api/products')
                            .then(response => response.json())
                            .then(data => {
                                const product = data.products.find(p => p.url === url);
                                if (product) {
                                    updateLoadingCard(product, index);
                                    processedUrls.add(url);
                                    console.log(`Updated product: ${product.name}`);
                                }
                            })
                            .catch(error => console.error('Error fetching product data:', error));
                    }
                });
                
                // Check if all URLs have been processed
                const allProcessed = urls.every(url => processedUrls.has(url));
                
                if (allProcessed) {
                    clearInterval(updateInterval);
                    console.log('All products processed, stopping real-time updates');
                    // Final refresh to get all data
                    setTimeout(() => {
                        loadProducts();
                    }, 1000);
                }
            }
        } catch (error) {
            console.error('Error in real-time update:', error);
        }
    }, 500); // Check every 500ms for even faster updates
}

// Update loading card with real data
function updateLoadingCard(product, index) {
    const loadingCard = document.querySelector(`[data-index="${index}"]`);
    if (loadingCard) {
        loadingCard.outerHTML = createProductCard(product);
    }
}

// Delete product
async function deleteProduct(productId) {
    if (!confirm('Are you sure you want to delete this product?')) {
        return;
    }
    
    try {
        const response = await fetch(`/api/products/${productId}`, {
            method: 'DELETE'
        });
        
        if (response.ok) {
            showSuccess('Product deleted successfully');
            loadProducts();
        } else {
            throw new Error('Failed to delete product');
        }
    } catch (error) {
        console.error('Error deleting product:', error);
        showError('Failed to delete product');
    }
}

// Status display functions
function showLoading(container) {
    container.innerHTML = `
        <div class="loading-message">
            <i class="fas fa-spinner fa-spin"></i>
            <p>Loading products...</p>
        </div>
    `;
}

function showSuccess(message) {
    console.log('Success:', message);
}

function showError(message) {
    console.error('Error:', message);
}

function showLoadingStatus(message) {
    crawlingStatus.className = 'status-box loading';
    crawlingStatus.innerHTML = `
        <i class="fas fa-spinner fa-spin"></i>
        <span>${message}</span>
        <div class="loading-progress"></div>
    `;
}

function showSuccessStatus(message) {
    crawlingStatus.className = 'status-box success';
    crawlingStatus.innerHTML = `
        <i class="fas fa-check-circle"></i>
        <span>${message}</span>
    `;
}

function showErrorStatus(message) {
    crawlingStatus.className = 'status-box error';
    crawlingStatus.innerHTML = `
        <i class="fas fa-exclamation-circle"></i>
        <span>${message}</span>
    `;
}

// Open product URL
function openProductUrl(url) {
    if (url && url !== 'Not found') {
        window.open(url, '_blank');
    }
}

// Generate star rating display
function generateStars(rating) {
    if (!rating || rating === 'N/A') {
        return '<span class="no-rating">No rating</span>';
    }
    
    const numRating = parseFloat(rating);
    if (isNaN(numRating)) {
        return '<span class="no-rating">No rating</span>';
    }
    
    let stars = '';
    const fullStars = Math.floor(numRating);
    const hasHalfStar = numRating % 1 >= 0.5;
    
    // Full stars
    for (let i = 0; i < fullStars; i++) {
        stars += '<i class="fas fa-star"></i>';
    }
    
    // Half star
    if (hasHalfStar) {
        stars += '<i class="fas fa-star-half-alt"></i>';
    }
    
    // Empty stars
    const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    for (let i = 0; i < emptyStars; i++) {
        stars += '<i class="far fa-star"></i>';
    }
    
    return stars;
}

// Copy ASIN to clipboard
function copyToClipboard(text) {
    if (text === 'N/A') {
        showError('No ASIN available to copy');
        return;
    }
    
    navigator.clipboard.writeText(text).then(() => {
        showSuccess(`ASIN ${text} copied to clipboard!`);
    }).catch(err => {
        console.error('Failed to copy: ', err);
        showError('Failed to copy ASIN');
    });
}

// Search ASIN on Amazon
function searchASIN(asin) {
    if (asin === 'N/A') {
        showError('No ASIN available to search');
        return;
    }
    
    const searchUrl = `https://www.amazon.com/s?k=${asin}`;
    window.open(searchUrl, '_blank');
    showSuccess(`Searching for ASIN ${asin} on Amazon`);
}

// Show success message
function showSuccess(message) {
    // Create temporary success notification
    const notification = document.createElement('div');
    notification.className = 'success-notification';
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #28a745;
        color: white;
        padding: 12px 20px;
        border-radius: 6px;
        z-index: 1000;
        font-size: 14px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        animation: slideIn 0.3s ease;
    `;
    
    document.body.appendChild(notification);
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 3000);
}

// Show error message
function showError(message) {
    // Create temporary error notification
    const notification = document.createElement('div');
    notification.className = 'error-notification';
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #dc3545;
        color: white;
        padding: 12px 20px;
        border-radius: 6px;
        z-index: 1000;
        font-size: 14px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        animation: slideIn 0.3s ease;
    `;
    
    document.body.appendChild(notification);
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 3000);
}

// Settings functions
async function loadCrawlInterval() {
    try {
        const response = await fetch('/api/settings/crawl-interval');
        if (response.ok) {
            const data = await response.json();
            document.getElementById('crawlInterval').value = data.interval;
        }
    } catch (error) {
        console.error('Error loading crawl interval:', error);
    }
}

async function saveCrawlInterval() {
    const interval = document.getElementById('crawlInterval').value;
    
    try {
        const response = await fetch('/api/settings/crawl-interval', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ interval: parseInt(interval) })
        });
        
        if (response.ok) {
            showSuccess('Crawl interval updated successfully');
        } else {
            throw new Error('Failed to update crawl interval');
        }
    } catch (error) {
        console.error('Error updating crawl interval:', error);
        showError('Failed to update crawl interval');
    }
}

async function clearDatabase() {
    if (confirm('Are you sure you want to clear all data? This action cannot be undone.')) {
        try {
            const response = await fetch('/api/settings/clear-database', {
                method: 'POST'
            });
            
            if (response.ok) {
                showSuccess('Database cleared successfully');
                loadProducts(); // Reload products
            } else {
                throw new Error('Failed to clear database');
            }
        } catch (error) {
            console.error('Error clearing database:', error);
            showError('Failed to clear database');
        }
    }
} 