#ifndef MOVIEITEM_H
#define MOVIEITEM_H

#include <QQuickItem>
#include <QMovie>

class MovieItem : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool paused MEMBER paused WRITE setPaused NOTIFY pausedChanged)
    Q_PROPERTY(int currentFrame READ currentFrame WRITE setCurrentFrame NOTIFY frameChanged)
    Q_PROPERTY(QSize sourceSize READ sourceSize WRITE setSourceSize NOTIFY sourceSizeChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY frameCountChanged)
    Q_PROPERTY(bool cache READ cache WRITE setCache NOTIFY cacheChanged)

public:
    MovieItem();

    QUrl source() const;
    void setSource(QUrl source);

    void setPaused(bool paused);

    int currentFrame() const;
    void setCurrentFrame(int frame);

    QSize sourceSize() const;
    void setSourceSize(QSize size);

    int frameCount() const;

    bool cache() const;
    void setCache(bool cache);

signals:
    void sourceChanged();
    void pausedChanged();
    void frameChanged();
    void sourceSizeChanged();
    void frameCountChanged();
    void cacheChanged();

protected:
    virtual QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData*) override;

private:
    void updateSize();

private:
    QMovie *movie;
    bool paused;
};

#endif // MOVIEITEM_H
