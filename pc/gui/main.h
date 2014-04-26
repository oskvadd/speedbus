#include <libconfig.h>

#define MAX_TEXT_BUFFER 200     // Maximum text buffer for preferences
#define MAX_STR(X)  ((strlen(X)) > (MAX_TEXT_BUFFER-1) ? (MAX_TEXT_BUFFER-1) : (strlen(X)+1)) 
// If the var_dst is sizeof MAX_TEXT_BUFFER, then strncpy(var_dst, var_src, MAX_STR(var_src))  


void m_send(void *ptr, char *data, int len);
static void get_vars_load(void *data, char *p_data, int counter);
static int get_variable_gui(void *data, int var_id, bool from_gui);
static void speedbus_fill_devlist(void *data);
gboolean rdeve_load_event(GtkTreeView * treeview, GtkTreePath * path, GtkTreeViewColumn * col, gpointer data);
gboolean rdeve_load_event_(int levent, gpointer data);
