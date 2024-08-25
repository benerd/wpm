<?php
/**
 * Namespace functions.
 *
 * @package website-performance-monitor.
 */

namespace WebsitePerformanceMonitor;

/**
 * Bootstrap the plugin.
 *
 * Registers actions and filters required to run the plugin.
 */
function setup(): void {
    // Add the admin menu page.
    add_action('admin_menu', __NAMESPACE__ . '\\add_performance_monitor_menu_page');

    add_action('admin_enqueue_scripts', __NAMESPACE__ . '\\enqueue_react_app');
}

// Create a function to add the menu page
function add_performance_monitor_menu_page(): void {
    add_menu_page(
        'Website Performance Monitor',
        'Website Performance Monitor',
        'manage_options',
        'website-performance-monitor',
        __NAMESPACE__ . '\\display_performance_monitor_page', 
        'dashicons-chart-area',
        100,
    );
}

// Create a function to display the page
function display_performance_monitor_page(): void {
    // Create a div where the React app will be rendered
    echo '<div id="app"></div>';
}

function enqueue_react_app() {
    // Only enqueue the script on your plugin's page
    $screen = get_current_screen();

    if ($screen->id !== 'toplevel_page_website-performance-monitor')  {
        return;
    }

    // Get the asset manifest
    $asset_manifest = json_decode(file_get_contents( WPM_PATH . '/app/build/asset-manifest.json' ), true)['files'];

    // Find the main.js file
    $main_js = $asset_manifest['main.js'];

    
    // Enqueue the main.js file
    wp_enqueue_script(
        'my-plugin-app',
        plugins_url( 'website-performance-monitor/app/build/' . $main_js, WPM_PATH ),
        ['wp-element'],
        '' . time() . '',
        true,
    );
}
