Folder PATH listing
Volume serial number is 00000025 84A3:CC0A
C:.
¦   folder_structure.md
¦   injection_container.dart
¦   main.dart
¦   
+---core
¦   +---api
¦   ¦       api_client.dart
¦   ¦       
¦   +---config
¦   ¦       app_config.dart
¦   ¦       router_config.dart
¦   ¦       supabase_config.dart
¦   ¦       
¦   +---constants
¦   ¦       app_colors.dart
¦   ¦       app_icons.dart
¦   ¦       app_images.dart
¦   ¦       app_routes.dart
¦   ¦       app_sizes.dart
¦   ¦       app_strings.dart
¦   ¦       app_text_styles.dart
¦   ¦       supabase_constants.dart
¦   ¦       
¦   +---errors
¦   ¦   ¦   exceptions.dart
¦   ¦   ¦   failures.dart
¦   ¦   ¦   
¦   ¦   +---exceptions
¦   ¦   ¦       auth_exceptions.dart
¦   ¦   ¦       
¦   ¦   +---failures
¦   ¦           auth_failures.dart
¦   ¦           
¦   +---network
¦   ¦       dio_client.dart
¦   ¦       network_info.dart
¦   ¦       
¦   +---routes
¦   ¦       app_router.dart
¦   ¦       route_names.dart
¦   ¦       route_transitions.dart
¦   ¦       
¦   +---theme
¦   ¦       app_theme.dart
¦   ¦       
¦   +---utils
¦   ¦       app_state_notifier.dart
¦   ¦       date_time_utils.dart
¦   ¦       debouncer.dart
¦   ¦       extensions.dart
¦   ¦       formatters.dart
¦   ¦       logger.dart
¦   ¦       session_expiry_policy.dart
¦   ¦       size_config.dart
¦   ¦       validators.dart
¦   ¦       
¦   +---widgets
¦           custom_app_bar.dart
¦           custom_textField.dart
¦           empty_state.dart
¦           error_snackbar.dart
¦           error_state.dart
¦           header.dart
¦           info_chip.dart
¦           loading_indicator.dart
¦           meta_row.dart
¦           retry_button.dart
¦           
+---features
¦   +---auth
¦   ¦   +---data
¦   ¦   ¦   +---datasources
¦   ¦   ¦   ¦       auth_data_source.dart
¦   ¦   ¦   ¦       auth_data_source_impl.dart
¦   ¦   ¦   ¦       
¦   ¦   ¦   +---models
¦   ¦   ¦   ¦       customer_address_model.dart
¦   ¦   ¦   ¦       customer_model.dart
¦   ¦   ¦   ¦       
¦   ¦   ¦   +---repositories
¦   ¦   ¦           auth_repository_impl.dart
¦   ¦   ¦           
¦   ¦   +---domain
¦   ¦   ¦   +---entities
¦   ¦   ¦   ¦       customer_address_entity.dart
¦   ¦   ¦   ¦       customer_address_input.dart
¦   ¦   ¦   ¦       customer_entity.dart
¦   ¦   ¦   ¦       
¦   ¦   ¦   +---repositories
¦   ¦   ¦   ¦       auth_repository.dart
¦   ¦   ¦   ¦       
¦   ¦   ¦   +---usecases
¦   ¦   ¦           check_startup_session.dart
¦   ¦   ¦           create_customer_address.dart
¦   ¦   ¦           forgot_password.dart
¦   ¦   ¦           get_current_client.dart
¦   ¦   ¦           get_current_location_address.dart
¦   ¦   ¦           reset_password.dart
¦   ¦   ¦           send_otp.dart
¦   ¦   ¦           sign_in.dart
¦   ¦   ¦           sign_out.dart
¦   ¦   ¦           sign_up.dart
¦   ¦   ¦           update_client_profile.dart
¦   ¦   ¦           verify_otp.dart
¦   ¦   ¦           verify_password_reset_otp.dart
¦   ¦   ¦           
¦   ¦   +---presentation
¦   ¦       +---bloc
¦   ¦       ¦       auth_bloc.dart
¦   ¦       ¦       auth_event.dart
¦   ¦       ¦       auth_state.dart
¦   ¦       ¦       
¦   ¦       +---screens
¦   ¦       ¦       email_verification_screen.dart
¦   ¦       ¦       forgotPassword.dart
¦   ¦       ¦       login_screen.dart
¦   ¦       ¦       resetPassword.dart
¦   ¦       ¦       signup_screen.dart
¦   ¦       ¦       welcome_screen.dart
¦   ¦       ¦       
¦   ¦       +---widgets
¦   ¦               auth_footer.dart
¦   ¦               auth_header.dart
¦   ¦               client_auth_form.dart
¦   ¦               password_strength_meter.dart
¦   ¦               password_visibility_toggle.dart
¦   ¦               session_checking_splash.dart
¦   ¦               
¦   +---dashboard
¦   ¦       dashboard_wrapper.dart
¦   ¦       
¦   +---home
¦   ¦   +---presentation
¦   ¦       +---bloc
¦   ¦       ¦       home_bloc.dart
¦   ¦       ¦       home_event.dart
¦   ¦       ¦       home_state.dart
¦   ¦       ¦       
¦   ¦       +---pages
¦   ¦       ¦       home_screen.dart
¦   ¦       ¦       
¦   ¦       +---widgets
¦   ¦               category_grid.dart
¦   ¦               greeting_header.dart
¦   ¦               search_bar.dart
¦   ¦               trending_services.dart
¦   ¦               
¦   +---membership
¦       +---data
¦       ¦   +---datasources
¦       ¦   ¦       membership_remote_data_source.dart
¦       ¦   ¦       
¦       ¦   +---models
¦       ¦   ¦       membership_application_model.dart
¦       ¦   ¦       member_model.dart
¦       ¦   ¦       profile_model.dart
¦       ¦   ¦       
¦       ¦   +---repositories
¦       ¦           membership_repository_impl.dart
¦       ¦           
¦       +---domain
¦       ¦   +---entities
¦       ¦   ¦       membership_application_entity.dart
¦       ¦   ¦       member_entity.dart
¦       ¦   ¦       profile_entity.dart
¦       ¦   ¦       
¦       ¦   +---repositories
¦       ¦   ¦       membership_repository.dart
¦       ¦   ¦       
¦       ¦   +---usecases
¦       ¦           cancel_membership_application.dart
¦       ¦           get_membership_status.dart
¦       ¦           submit_membership_application.dart
¦       ¦           
¦       +---presentation
¦           +---bloc
¦           ¦       membership_bloc.dart
¦           ¦       membership_event.dart
¦           ¦       membership_state.dart
¦           ¦       
¦           +---pages
¦                   membership_application_page.dart
¦                   membership_status_page.dart
¦                   
+---shared
    ¦   custom_bottom_nav_bar.dart
    ¦   
    +---widgets
