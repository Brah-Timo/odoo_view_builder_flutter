// lib/data/models/view_template.dart
//
// Built-in view templates ready to use as starting points.

import 'package:uuid/uuid.dart';
import 'odoo_form.dart';
import 'odoo_field.dart';
import 'odoo_group.dart';

/// A template entry shown in the Template Library screen
class ViewTemplate {
  final String id;
  final String title;
  final String description;
  final String category;
  final String model;
  final ViewType viewType;
  final String? iconEmoji;
  final OdooView Function() build;

  const ViewTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.model,
    required this.viewType,
    this.iconEmoji,
    required this.build,
  });
}

/// Registry of all built-in templates
class BuiltInTemplates {
  BuiltInTemplates._();

  static OdooField _f(String name, OdooFieldType type, {String? label, bool required = false, bool readonly = false, String? widget}) {
    return OdooField.create(name: name, fieldType: type, label: label)
        .copyWith(required: required, readonly: readonly, widget: widget);
  }

  static OdooGroup _g(String label, List<OdooField> fields) {
    final now = DateTime.now();
    return OdooGroup(
      id: const Uuid().v4(),
      label: label,
      fields: fields,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ─── Contact Form ─────────────────────────────────────────────────────────────
  static OdooView buildContactForm() {
    return OdooView.create(
      name: 'Contact Form',
      model: 'res.partner',
      viewType: ViewType.form,
    ).copyWith(
      id: 'view_partner_form_custom',
      groups: [
        _g('General Information', [
          _f('name', OdooFieldType.char, label: 'Name', required: true),
          _f('email', OdooFieldType.char, label: 'Email', widget: 'email'),
          _f('phone', OdooFieldType.char, label: 'Phone', widget: 'phone'),
          _f('mobile', OdooFieldType.char, label: 'Mobile', widget: 'phone'),
          _f('website', OdooFieldType.char, label: 'Website', widget: 'url'),
        ]),
        _g('Address', [
          _f('street', OdooFieldType.char, label: 'Street'),
          _f('street2', OdooFieldType.char, label: 'Street 2'),
          _f('city', OdooFieldType.char, label: 'City'),
          _f('zip', OdooFieldType.char, label: 'ZIP'),
          _f('country_id', OdooFieldType.many2one, label: 'Country'),
        ]),
      ],
    );
  }

  // ─── Sale Order Form ──────────────────────────────────────────────────────────
  static OdooView buildSaleOrderForm() {
    return OdooView.create(
      name: 'Sale Order Form',
      model: 'sale.order',
      viewType: ViewType.form,
    ).copyWith(
      id: 'view_sale_order_form_custom',
      topLevelFields: [
        _f('state', OdooFieldType.selection, label: 'Status', widget: 'statusbar'),
      ],
      groups: [
        _g('Order Details', [
          _f('name', OdooFieldType.char, label: 'Order Reference', readonly: true),
          _f('partner_id', OdooFieldType.many2one, label: 'Customer', required: true),
          _f('date_order', OdooFieldType.datetime, label: 'Order Date'),
          _f('validity_date', OdooFieldType.date, label: 'Expiration'),
          _f('user_id', OdooFieldType.many2one, label: 'Salesperson'),
          _f('team_id', OdooFieldType.many2one, label: 'Sales Team'),
        ]),
        _g('Pricing', [
          _f('pricelist_id', OdooFieldType.many2one, label: 'Pricelist'),
          _f('currency_id', OdooFieldType.many2one, label: 'Currency'),
          _f('payment_term_id', OdooFieldType.many2one, label: 'Payment Terms'),
        ]),
      ],
      pages: [
        NotebookPage(
          id: 'page_order_lines',
          label: 'Order Lines',
          fields: [
            _f('order_line', OdooFieldType.one2many, label: 'Order Lines'),
          ],
        ),
        NotebookPage(
          id: 'page_other_info',
          label: 'Other Information',
          groups: [
            _g('Shipping', [
              _f('commitment_date', OdooFieldType.datetime, label: 'Delivery Date'),
              _f('warehouse_id', OdooFieldType.many2one, label: 'Warehouse'),
            ]),
            _g('Invoicing', [
              _f('invoice_status', OdooFieldType.selection, label: 'Invoice Status'),
              _f('partner_invoice_id', OdooFieldType.many2one, label: 'Invoice Address'),
              _f('partner_shipping_id', OdooFieldType.many2one, label: 'Delivery Address'),
            ]),
          ],
        ),
      ],
    );
  }

  // ─── Product Form ─────────────────────────────────────────────────────────────
  static OdooView buildProductForm() {
    return OdooView.create(
      name: 'Product Form',
      model: 'product.template',
      viewType: ViewType.form,
    ).copyWith(
      id: 'view_product_template_form_custom',
      groups: [
        _g('Product Details', [
          _f('name', OdooFieldType.char, label: 'Product Name', required: true),
          _f('categ_id', OdooFieldType.many2one, label: 'Category'),
          _f('type', OdooFieldType.selection, label: 'Product Type'),
          _f('uom_id', OdooFieldType.many2one, label: 'Unit of Measure'),
          _f('uom_po_id', OdooFieldType.many2one, label: 'Purchase UoM'),
          _f('active', OdooFieldType.boolean, label: 'Active'),
        ]),
        _g('Pricing', [
          _f('list_price', OdooFieldType.float, label: 'Sales Price', widget: 'monetary'),
          _f('standard_price', OdooFieldType.float, label: 'Cost', widget: 'monetary'),
          _f('taxes_id', OdooFieldType.many2many, label: 'Customer Taxes', widget: 'many2many_tags'),
        ]),
      ],
      pages: [
        NotebookPage(
          id: 'page_description',
          label: 'Description',
          fields: [
            _f('description', OdooFieldType.html, label: 'Internal Notes'),
            _f('description_sale', OdooFieldType.text, label: 'Sales Description'),
          ],
        ),
      ],
    );
  }

  // ─── Task Tree ────────────────────────────────────────────────────────────────
  static OdooView buildTaskTree() {
    return OdooView.create(
      name: 'Task List',
      model: 'project.task',
      viewType: ViewType.tree,
    ).copyWith(
      id: 'view_task_tree_custom',
      topLevelFields: [
        _f('name', OdooFieldType.char, label: 'Task Name'),
        _f('project_id', OdooFieldType.many2one, label: 'Project'),
        _f('user_ids', OdooFieldType.many2many, label: 'Assignees', widget: 'many2many_tags'),
        _f('stage_id', OdooFieldType.many2one, label: 'Stage'),
        _f('date_deadline', OdooFieldType.date, label: 'Deadline'),
        _f('priority', OdooFieldType.selection, label: 'Priority', widget: 'priority'),
      ],
    );
  }

  // ─── CRM Lead Kanban ──────────────────────────────────────────────────────────
  static OdooView buildLeadKanban() {
    return OdooView.create(
      name: 'CRM Pipeline',
      model: 'crm.lead',
      viewType: ViewType.kanban,
    ).copyWith(
      id: 'view_crm_lead_kanban_custom',
      topLevelFields: [
        _f('name', OdooFieldType.char, label: 'Lead Name'),
        _f('partner_id', OdooFieldType.many2one, label: 'Customer'),
        _f('expected_revenue', OdooFieldType.float, label: 'Expected Revenue', widget: 'monetary'),
        _f('user_id', OdooFieldType.many2one, label: 'Salesperson'),
        _f('stage_id', OdooFieldType.many2one, label: 'Stage'),
        _f('priority', OdooFieldType.selection, label: 'Priority', widget: 'priority'),
      ],
    );
  }

  // ─── Employee Form ────────────────────────────────────────────────────────────
  static OdooView buildEmployeeForm() {
    return OdooView.create(
      name: 'Employee Form',
      model: 'hr.employee',
      viewType: ViewType.form,
    ).copyWith(
      id: 'view_hr_employee_form_custom',
      groups: [
        _g('Employee Info', [
          _f('name', OdooFieldType.char, label: 'Employee Name', required: true),
          _f('job_id', OdooFieldType.many2one, label: 'Job Position'),
          _f('job_title', OdooFieldType.char, label: 'Job Title'),
          _f('department_id', OdooFieldType.many2one, label: 'Department'),
          _f('parent_id', OdooFieldType.many2one, label: 'Manager'),
          _f('work_email', OdooFieldType.char, label: 'Work Email', widget: 'email'),
          _f('work_phone', OdooFieldType.char, label: 'Work Phone', widget: 'phone'),
        ]),
        _g('Work Information', [
          _f('resource_calendar_id', OdooFieldType.many2one, label: 'Working Hours'),
          _f('tz', OdooFieldType.selection, label: 'Timezone'),
          _f('company_id', OdooFieldType.many2one, label: 'Company'),
        ]),
      ],
    );
  }

  // ─── All Templates List ───────────────────────────────────────────────────────
  static List<ViewTemplate> all = [
    ViewTemplate(
      id: 'tpl_contact_form',
      title: 'Contact Form',
      description: 'Standard res.partner form with address and contact info',
      category: 'CRM',
      model: 'res.partner',
      viewType: ViewType.form,
      iconEmoji: '👤',
      build: buildContactForm,
    ),
    ViewTemplate(
      id: 'tpl_sale_order_form',
      title: 'Sale Order Form',
      description: 'Full sale.order form with notebook pages and statusbar',
      category: 'Sales',
      model: 'sale.order',
      viewType: ViewType.form,
      iconEmoji: '🛒',
      build: buildSaleOrderForm,
    ),
    ViewTemplate(
      id: 'tpl_product_form',
      title: 'Product Form',
      description: 'product.template form with pricing and description tabs',
      category: 'Inventory',
      model: 'product.template',
      viewType: ViewType.form,
      iconEmoji: '📦',
      build: buildProductForm,
    ),
    ViewTemplate(
      id: 'tpl_task_tree',
      title: 'Task List View',
      description: 'project.task tree view with common columns',
      category: 'Project',
      model: 'project.task',
      viewType: ViewType.tree,
      iconEmoji: '✅',
      build: buildTaskTree,
    ),
    ViewTemplate(
      id: 'tpl_lead_kanban',
      title: 'CRM Pipeline',
      description: 'crm.lead kanban with revenue and priority',
      category: 'CRM',
      model: 'crm.lead',
      viewType: ViewType.kanban,
      iconEmoji: '🎯',
      build: buildLeadKanban,
    ),
    ViewTemplate(
      id: 'tpl_employee_form',
      title: 'Employee Form',
      description: 'hr.employee form with work info',
      category: 'HR',
      model: 'hr.employee',
      viewType: ViewType.form,
      iconEmoji: '👔',
      build: buildEmployeeForm,
    ),
  ];
}
