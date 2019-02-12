# dita-embed-html-mathml-svg
DITA Open Toolkit plugin which allows you to embed referenced MathML and SVG images in the HTML5 and XHTML output.

The plugin was tested using DITA Open Toolkit 3.2.1 and it aims to solve two use cases:

1. When a DITA topic has an image reference to a MathML document, when publishing to HTML-based outputs in order to have the MathML content properly rendered in the Web Browser the reference to the MathML document needs to be expanded in-place in the HTML output. In web browsers other than Firefox the MathJax Javscript libraries also need to be referenced in the HTML document header: https://www.oxygenxml.com/doc/versions/20.1/ug-editor/topics/mathjax-webhelp-x-modes2.html

1. When a DITA topic has an image reference to an SVG and the SVG document contains animation (custom Javascript code) in order for the animation to properly work in the web browser, the SVG content needs to be expanded in-place in the HTML document. Setting the **@outputclass='embed'** attribute on the DITA **image** reference will triggeer this in-place expansion of the SVG in the HTML document.

The "samples" folder contains a DITA topic with two referenced images (MathML and SVG) and can be used to test that the plugin works.

The plugin uses XSLT utility functions copied from the DITA Community plugins developed by Eliot Kimber: https://github.com/dita-community/org.dita-community.common.xslt
