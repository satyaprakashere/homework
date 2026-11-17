// guardrail_macro/src/lib.rs
extern crate proc_macro;
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, Item, Type};
use syn::visit::{self, Visit};

struct GuardrailVisitor {
    has_error: bool,
    error_message: String,
}

impl<'ast> Visit<'ast> for GuardrailVisitor {
    fn visit_type(&mut self, node: &'ast Type) {
        match node {
            Type::Reference(ty_ref) => {
                if ty_ref.mutability.is_some() {
                    self.has_error = true;
                    self.error_message = "rust-- error: Mutable references (&mut T) are banned.".into();
                }
                if ty_ref.lifetime.is_some() {
                    self.has_error = true;
                    self.error_message = "rust-- error: Lifetime annotations ('a) are banned.".into();
                }
            }
            _ => {}
        }
        visit::visit_type(self, node);
    }
}

#[proc_macro_attribute]
pub fn rust_minus(_attr: TokenStream, item: TokenStream) -> TokenStream {
    let input = parse_macro_input!(item as Item);
    
    let mut visitor = GuardrailVisitor {
        has_error: false,
        error_message: String::new(),
    };
    
    visitor.visit_item(&input);

    if visitor.has_error {
        let err = visitor.error_message;
        return syn::Error::new(proc_macro2::Span::call_site(), err)
            .to_compile_error()
            .into();
    }

    quote! { #input }.into()
}