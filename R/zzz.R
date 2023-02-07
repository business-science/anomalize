
# By default set time_scale_template_options to time_scale_template()
.onLoad = function(libname, pkgname) {
    options(
        time_scale_template = time_scale_template()
    )
}

# .onAttach <- function(libname, pkgname) {
#
#     bsu_rule_color <- "#2c3e50"
#     bsu_main_color <- "#1f78b4"
#
#     # Check Theme: If Dark, Update Colors
#     if (rstudioapi::isAvailable()) {
#         theme <- rstudioapi::getThemeInfo()
#         if (theme$dark) {
#             bsu_rule_color <- "#7FD2FF"
#             bsu_main_color <- "#18bc9c"
#         }
#     }
#
#     bsu_main <- crayon::make_style(bsu_main_color)
#
#     msg <- paste0(
#         cli::rule(left = "Use anomalize to improve your Forecasts by 50%!", col = bsu_rule_color, line = 2),
#         bsu_main('\nBusiness Science offers a 1-hour course - Lab #18: Time Series Anomaly Detection!\n'),
#         bsu_main('</> Learn more at: https://university.business-science.io/p/learning-labs-pro </>')
#     )
#
#     packageStartupMessage(msg)
#
# }
