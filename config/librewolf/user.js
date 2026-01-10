// Librewolf user.js
// Managed in dotfiles - symlink this to your profile directory
//
// Profile locations:
//   Arch (native): ~/.librewolf/<profile>/user.js
//   Arch (Flatpak): ~/.var/app/io.gitlab.librewolf-community/.librewolf/<profile>/user.js
//   macOS: ~/Library/Application Support/librewolf/<profile>/user.js

// =============================================================================
// STARTUP & HOMEPAGE
// =============================================================================
user_pref("browser.startup.homepage", "https://www.duckduckgo.com");
user_pref("browser.startup.page", 3); // Restore previous session
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSearch", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", true);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeBookmarks", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeDownloads", true);
user_pref("browser.newtabpage.activity-stream.section.highlights.includeVisited", true);

// =============================================================================
// TOOLBAR & UI CUSTOMIZATION
// =============================================================================
user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[\"sponsorblocker_ajay_app-browser-action\",\"jid0-3guet1r69sqnsrca5p8kx9ezc3u_jetpack-browser-action\",\"gelprec_smd_gmail_com-browser-action\",\"beyond20_kakaroto_homelinux_net-browser-action\",\"addon_darkreader_org-browser-action\"],\"nav-bar\":[\"back-button\",\"forward-button\",\"home-button\",\"stop-reload-button\",\"vertical-spacer\",\"urlbar-container\",\"downloads-button\",\"search-container\",\"_c45c406e-ab73-11d8-be73-000a95be3b12_-browser-action\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"ublock0_raymondhill_net-browser-action\",\"myallychou_gmail_com-browser-action\",\"unified-extensions-button\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"],\"vertical-tabs\":[],\"PersonalToolbar\":[\"personal-bookmarks\"]},\"seen\":[\"developer-button\",\"screenshot-button\",\"ublock0_raymondhill_net-browser-action\",\"_c45c406e-ab73-11d8-be73-000a95be3b12_-browser-action\",\"jid0-3guet1r69sqnsrca5p8kx9ezc3u_jetpack-browser-action\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"gelprec_smd_gmail_com-browser-action\",\"myallychou_gmail_com-browser-action\",\"beyond20_kakaroto_homelinux_net-browser-action\",\"sponsorblocker_ajay_app-browser-action\",\"addon_darkreader_org-browser-action\"],\"dirtyAreaCache\":[\"nav-bar\",\"vertical-tabs\",\"toolbar-menubar\",\"TabsToolbar\",\"PersonalToolbar\",\"unified-extensions-area\"],\"currentVersion\":23,\"newElementCount\":5}");
user_pref("browser.toolbars.bookmarks.visibility", "newtab");
user_pref("browser.theme.content-theme", 0); // Dark
user_pref("browser.theme.toolbar-theme", 0); // Dark

// Enable userChrome.css and userContent.css customization
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// =============================================================================
// SEARCH & URL BAR
// =============================================================================
user_pref("browser.urlbar.placeholderName", "DuckDuckGo");
user_pref("browser.urlbar.suggest.engines", false);
user_pref("browser.urlbar.suggest.openpage", false);
user_pref("browser.urlbar.suggest.topsites", false);

// =============================================================================
// DOWNLOADS
// =============================================================================
user_pref("browser.download.useDownloadDir", true);

// =============================================================================
// PRIVACY & SECURITY
// =============================================================================
user_pref("browser.contentblocking.category", "strict");
user_pref("privacy.donottrackheader.enabled", true);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.fingerprintingProtection", true);
user_pref("privacy.query_stripping.enabled", true);
user_pref("privacy.query_stripping.enabled.pbmode", true);
user_pref("privacy.bounceTrackingProtection.mode", 1);
user_pref("privacy.annotate_channels.strict_list.enabled", true);

// Clear on shutdown settings
user_pref("privacy.history.custom", true);
user_pref("privacy.clearOnShutdown_v2.downloads", false);
user_pref("privacy.clearOnShutdown_v2.formdata", true);

// Disable safe browsing remote lookups (privacy)
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.block_potentially_unwanted", false);
user_pref("browser.safebrowsing.downloads.remote.block_uncommon", false);
user_pref("browser.safebrowsing.downloads.remote.url", "");
user_pref("browser.safebrowsing.provider.google4.dataSharingURL", "");

// HTTPS-Only Mode
user_pref("dom.security.https_only_mode_ever_enabled", true);

// Disable TLS 0-RTT (security)
user_pref("security.tls.enable_0rtt_data", false);

// =============================================================================
// NETWORK & PERFORMANCE
// =============================================================================
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.connectivity-service.enabled", false);
user_pref("network.prefetch-next", false);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation", true);

// Disable region detection
user_pref("browser.region.network.url", "");
user_pref("browser.region.update.enabled", false);

// Disable captive portal detection
user_pref("captivedetect.canonicalURL", "");

// =============================================================================
// BEHAVIOR
// =============================================================================
user_pref("general.autoScroll", true); // Middle-click scroll
user_pref("layout.spellcheckDefault", 0); // Disable spellcheck
user_pref("accessibility.typeaheadfind.flashBar", 0);
user_pref("ui.key.menuAccessKeyFocuses", false); // Don't focus menu on Alt

// =============================================================================
// MEDIA & DRM
// =============================================================================
user_pref("media.eme.enabled", true); // Enable DRM (for Netflix, etc.)

// =============================================================================
// PASSWORDS & AUTOFILL
// =============================================================================
user_pref("signon.rememberSignons", true);
user_pref("signon.autofillForms", true);
user_pref("signon.generation.enabled", false); // Don't generate passwords (using external manager)
user_pref("dom.forms.autocomplete.formautofill", true);

// =============================================================================
// SIDEBAR
// =============================================================================
user_pref("sidebar.visibility", "hide-sidebar");

// =============================================================================
// DEVTOOLS
// =============================================================================
user_pref("devtools.debugger.remote-enabled", false);
user_pref("devtools.console.stdout.chrome", false);
