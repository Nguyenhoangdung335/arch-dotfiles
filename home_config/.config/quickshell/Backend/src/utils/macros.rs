#[macro_export]
macro_rules! proxy_span {
    ($event_name:expr, $destination:expr, $path:expr, $interface:expr, $prop:expr $(, $extra:tt)*) => {
        tracing::info_span!(
            $event_name,
            destination = ?$destination,
            path = ?$path,
            interface = %$interface,
            prop = %$prop
            $(, $extra)*
        )
    };
}

#[macro_export]
macro_rules! update_state_if_changed {
    ($state_tx:expr, $value:expr, $field:ident) => {
        if let Ok(parsed) = $value.try_into() {
            $state_tx.send_if_modified(|s| update_if_changed(&mut s.$field, parsed));
        }
    };
}
