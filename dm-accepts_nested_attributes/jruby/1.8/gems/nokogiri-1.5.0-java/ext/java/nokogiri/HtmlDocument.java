/**
 * (The MIT License)
 *
 * Copyright (c) 2008 - 2011:
 *
 * * {Aaron Patterson}[http://tenderlovemaking.com]
 * * {Mike Dalessio}[http://mike.daless.io]
 * * {Charles Nutter}[http://blog.headius.com]
 * * {Sergio Arbeo}[http://www.serabe.com]
 * * {Patrick Mahoney}[http://polycrystal.org]
 * * {Yoko Harada}[http://yokolet.blogspot.com]
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * 'Software'), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package nokogiri;

import nokogiri.internals.HtmlDomParserContext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.w3c.dom.Document;

/**
 * Class for Nokogiri::HTML::Document.
 *
 * @author sergio
 * @author Yoko Harada <yokolet@gmail.com>
 */
@JRubyClass(name="Nokogiri::HTML::Document", parent="Nokogiri::XML::Document")
public class HtmlDocument extends XmlDocument {

    public HtmlDocument(Ruby ruby, RubyClass klazz) {
        super(ruby, klazz);
    }
    
    public HtmlDocument(Ruby ruby, RubyClass klazz, Document doc) {
        super(ruby, klazz, doc);
    }

    @JRubyMethod(name="new", meta = true, rest = true, required=0)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz,
                                    IRubyObject[] args) {
        HtmlDocument htmlDocument = null;
        try {
            Document docNode = createNewDocument();
            htmlDocument = (HtmlDocument) NokogiriService.HTML_DOCUMENT_ALLOCATOR.allocate(context.getRuntime(), (RubyClass) klazz);
            htmlDocument.setNode(context, docNode);
        } catch (Exception ex) {
            throw context.getRuntime().newRuntimeError("couldn't create document: "+ex.toString());
        }

        RuntimeHelpers.invoke(context, htmlDocument, "initialize", args);

        return htmlDocument;
    }

    public static IRubyObject do_parse(ThreadContext context,
                                       IRubyObject klass,
                                       IRubyObject[] args) {
        Ruby ruby = context.getRuntime();
        Arity.checkArgumentCount(ruby, args, 4, 4);
        HtmlDomParserContext ctx =
            new HtmlDomParserContext(ruby, args[2], args[3]);
        ctx.setInputSource(context, args[0], args[1]);
        return ctx.parse(context, klass, args[1]);
    }

    /*
     * call-seq:
     *  read_io(io, url, encoding, options)
     *
     * Read the HTML document from +io+ with given +url+, +encoding+,
     * and +options+.  See Nokogiri::HTML.parse
     */
    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_io(ThreadContext context,
                                      IRubyObject cls,
                                      IRubyObject[] args) {
        return do_parse(context, cls, args);
    }

    /*
     * call-seq:
     *  read_memory(string, url, encoding, options)
     *
     * Read the HTML document contained in +string+ with given +url+, +encoding+,
     * and +options+.  See Nokogiri::HTML.parse
     */
    @JRubyMethod(meta = true, rest = true)
    public static IRubyObject read_memory(ThreadContext context,
                                          IRubyObject cls,
                                          IRubyObject[] args) {
        return do_parse(context, cls, args);
    }
}
