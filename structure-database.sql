-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.contacts (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  name character varying NOT NULL,
  type USER-DEFINED DEFAULT 'CUSTOMER'::contact_type,
  phone character varying,
  address text,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT contacts_pkey PRIMARY KEY (id)
);
CREATE TABLE public.products (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  sku character varying UNIQUE,
  name character varying NOT NULL,
  base_unit character varying NOT NULL DEFAULT 'pcs'::character varying,
  current_stock numeric DEFAULT 0,
  average_cost numeric DEFAULT 0,
  latest_selling_price numeric DEFAULT 0,
  conversion_rules jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  variant character varying,
  category character varying,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT products_pkey PRIMARY KEY (id)
);
CREATE TABLE public.stock_ledger (
  id bigint NOT NULL DEFAULT nextval('stock_ledger_id_seq'::regclass),
  product_id uuid,
  transaction_id uuid,
  date timestamp with time zone DEFAULT now(),
  type USER-DEFINED NOT NULL,
  qty_change numeric NOT NULL,
  stock_after numeric NOT NULL,
  notes text,
  created_by uuid,
  CONSTRAINT stock_ledger_pkey PRIMARY KEY (id),
  CONSTRAINT stock_ledger_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id),
  CONSTRAINT stock_ledger_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id),
  CONSTRAINT stock_ledger_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.transaction_items (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  transaction_id uuid,
  product_id uuid,
  input_qty numeric NOT NULL,
  input_unit character varying NOT NULL,
  input_price numeric NOT NULL,
  conversion_rate numeric NOT NULL DEFAULT 1,
  base_qty numeric DEFAULT (input_qty * conversion_rate),
  cost_price_at_moment numeric DEFAULT 0,
  subtotal numeric DEFAULT (input_qty * input_price),
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT transaction_items_pkey PRIMARY KEY (id),
  CONSTRAINT transaction_items_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id),
  CONSTRAINT transaction_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id)
);
CREATE TABLE public.transactions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  type USER-DEFINED NOT NULL,
  contact_id uuid,
  transaction_date timestamp with time zone DEFAULT now(),
  invoice_number character varying UNIQUE,
  total_amount numeric DEFAULT 0,
  payment_method character varying,
  input_source character varying DEFAULT 'MANUAL'::character varying,
  evidence_url text,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT transactions_pkey PRIMARY KEY (id),
  CONSTRAINT transactions_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id),
  CONSTRAINT transactions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  username character varying NOT NULL UNIQUE,
  full_name character varying,
  role USER-DEFINED DEFAULT 'STAFF'::user_role,
  password_hash text NOT NULL,
  biometric_token text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  last_login_at timestamp with time zone,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id)
);