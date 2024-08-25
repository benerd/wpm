<?php
/**
 * Rest API: Google PSI.
 *
 * @package website-performance-monitor.
 */

namespace ET\Leads\RestApi;

use WP_REST_Controller;
use WP_REST_Server;
use WP_REST_Request;
use WP_REST_Response;
use WP_Error;

use function ET\Leads\create_hubspot_lead;

use const ET\Leads\REST_API_NAMESPACE;

/**
 * Class Lead.
 */
class Google_PSI extends WP_REST_Controller {

	/**
	 * The namespace of this controller's route.
	 *
	 * @var string
	 */
	protected $namespace = REST_API_NAMESPACE . '/leads';

	/**
	 * Register the routes for the objects of the controller.
	 *
	 * @return void
	 */
	public function register_routes(): void {
		// Register rest route.
		register_rest_route(
			$this->namespace,
			'/newsletter-subscribe',
			[
				'methods'             => WP_REST_Server::CREATABLE,
				'callback'            => [ $this, 'create_item' ],
				'permission_callback' => '__return_true',
				'args'                => [
					'recaptcha_token' => [
						'required'          => true,
						'type'              => 'string',
						'default'           => '',
						'description'       => esc_html__( 'reCAPTCHA Token', 'et' ),
						'sanitize_callback' => 'sanitize_text_field',
					],
					'email_address'   => [
						'required'          => true,
						'type'              => 'string',
						'description'       => esc_html__( 'Email Address', 'et' ),
						'sanitize_callback' => 'sanitize_email',
						'validate_callback' => function ( $param ) {
							return filter_var( $param, FILTER_VALIDATE_EMAIL );
						},
					],
					'fields'          => [
						'required'          => true,
						'type'              => 'object',
						'description'       => esc_html__( 'Form Fields', 'et' ),
						'validate_callback' => function ( $param ) {
							return is_array( $param ) && ! empty( $param );
						},
					],
				],
			]
		);
	}

	/**
	 * Create a lead.
	 *
	 * @param WP_REST_Request $request Full details about the request.
	 *
	 * @return WP_REST_Response|WP_Error
	 */
	public function create_item( $request ): WP_REST_Response|WP_Error { // phpcs:ignore
		// Prepare lead data.
		$lead_data = [
			'recaptcha_token' => $request->get_param( 'recaptcha_token' ),
			'email_id'        => $request->get_param( 'email_address' ),
			'fields'          => (array) $request->get_param( 'fields' ),
		];

		// Create hubspot lead.
		$response = create_hubspot_lead( $lead_data );

		// Return response, if there is an error.
		if ( $response instanceof WP_Error ) {
			return $response;
		}

		// Return response.
		return rest_ensure_response( $response );
	}
}
