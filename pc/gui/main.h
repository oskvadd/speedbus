#include <libconfig.h>


void m_send(void *ptr, char *data, int len);
static void get_vars_load(void *data, char *p_data, int counter);
static int get_variable_gui(void *data, int var_id, bool from_gui);
static void speedbus_fill_devlist(void *data);
gboolean rdeve_load_event(GtkTreeView * treeview, GtkTreePath * path, GtkTreeViewColumn * col, gpointer data);
